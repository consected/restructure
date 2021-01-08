# frozen_string_literal: true

module Messaging
  class MessageNotification < ActiveRecord::Base
    # Set the max number of recipients for a message, to avoid an unexpected nasty error spamming the whole organization
    MaxRecipients = 20
    StatusComplete = 'complete'
    StatusInProgress = 'in progress'
    StatusFailed = 'failed'
    ValidImportance = %w[Promotional Transactional].freeze

    include WorksWithItem

    belongs_to :app_type, class_name: 'Admin::AppType', optional: true
    belongs_to :user, optional: true
    belongs_to :master, optional: true
    # Even external systems that use a Rails based script to fire notifications must use a real user
    validates :user, presence: true, if: :app_type
    validates :master, presence: true, if: :app_type
    # No validation on app_type, since external systems may use Rails based script to fire notifications
    # validates :app_type, presence: true
    # No minimum on recipient_user_ids, since recipient_emails may be used instead
    validates :recipient_user_ids, length: { maximum: MaxRecipients }, if: :app_type
    validates :layout_template_name, presence: true
    validates :message_type, presence: true
    validate :content_template_specified?
    validate :item_type_valid?, if: :app_type

    scope :unhandled, -> { where status: nil }
    scope :limited_index, -> { limit 20 }

    attr_accessor :generated_text, :disabled, :admin_id, :for_item

    # Get a layout template by name and optionally message type
    # Useful as a quick check to see if a specific template has been defined before
    # instantiating a full MessageNotification
    def self.layout_template(name, message_type: :email)
      Admin::MessageTemplate.active.layout_templates.named name, type: message_type
    end

    def layout_template
      Admin::MessageTemplate.active.layout_templates.named layout_template_name, type: message_type
    end

    def content_template
      Admin::MessageTemplate.active.content_templates.named content_template_name, type: message_type
    end

    # The message notification works with an underlying item (likely an activity log implementation)
    # Handle getting and setting of the item and use of the actual class referenced
    # in the item_type / item_id attributes
    def item_class
      item_type&.classify&.constantize
    end

    def item
      @item ||= item_class.where(id: item_id).first if item_class
    end

    def item=(new_item)
      @item = new_item
      self.item_id = @item.id
      self.item_type = new_item.class.name.classify
    end

    def importance=(i)
      i = i.to_s.capitalize
      raise FphsException, "Incorrect importance: #{i}" unless i.in?(ValidImportance)

      super(i)
    end

    # Generate the message text from the templates and data
    def generate(ignore_missing: false)
      data = self.data
      if data.blank?
        raise FphsException, 'Data is blank and item_type / item_id does not return an item' unless item

        data = Formatter::Substitution.setup_data item, for_item
        data[:_subject] = subject
        data[:extra_substitutions] = extra_substitutions_data

        save!
      end

      raise FphsException, "Layout template #{layout_template_name} was not found" unless layout_template

      if content_template_name
        raise FphsException, "Content template #{content_template_name} was not found" unless content_template
      elsif !content_template_text
        raise FphsException, 'Content template name or text must be set'
      end

      self.generated_text = layout_template.generate content_template_name: content_template_name,
                                                     content_template_text: content_template_text,
                                                     data: data,
                                                     ignore_missing: ignore_missing
    end

    def generate_view(ignore_missing: false)
      generate(ignore_missing: ignore_missing)
    rescue FphsException => e
      "EXCEPTION: #{e}"
    end

    def recipient_users
      User.active.where(id: recipient_user_ids).all
    end

    def recipient_emails
      return @recipient_emails if @recipient_emails

      res = recipient_users.pluck(:email)
      self.recipient_data = res.uniq
      save
      res
    end

    def recipient_emails=(emails)
      @recipient_emails = emails
      self.recipient_data = emails
    end

    def recipient_sms_numbers
      return @recipient_numbers if @recipient_numbers

      if recipient_users&.present?
        recipient_users
          .reject { |u| !u.contact_info || u.contact_info.sms_number.blank? }
          .map { |u| u.contact_info&.sms_number }
          .uniq
      else
        recipient_data
      end
    end

    def recipient_sms_numbers=(nums)
      @recipient_numbers = nums
      self.recipient_data = nums
    end

    def extra_substitutions=(data)
      data = data.to_yaml if data.is_a?(Hash)

      super(data)
    end

    def extra_substitutions_data
      return @extra_substitutions_data if @extra_substitutions_data
      return unless extra_substitutions

      @extra_substitutions_data = YAML.safe_load(extra_substitutions, [Symbol])
    end

    def from_user_email
      res = super()
      return res if res

      res = Settings::NotificationsFromEmail || user&.email
      self.from_user_email = res
      save
      res
    end

    # Process this Messaging::MessageNotification record
    def handle_notification_now(logger: Rails.logger, for_item: nil, on_complete_config: {})
      logger.info "Handling item #{id}"
      update! status: StatusInProgress

      # Do not use a transaction, since we want successfully sent recipients to have a record saved so they
      # don't get hit again
      # Messaging::MessageNotification.transaction do
      begin
        # Check if recipient records have been set in the recipient_data
        # If not, we just have a list of emails of phones
        recipient_records = nil
        rd = recipient_data&.first
        if rd.is_a?(String)
          jrd = begin
            JSON.parse(rd)
          rescue StandardError
            nil
          end
          recipient_records = recipient_data.map { |r| JSON.parse(r) } if jrd.is_a?(Hash) && jrd['list_type']
        end

        self.for_item ||= for_item

        # If we have been passed recipient records, use these to generate each message for sending
        if recipient_records

          recipient_data = []
          recipient_records.each do |rec|
            rec.symbolize_keys!
            def_country_code = rec[:default_country_code]
            list_type = rec[:list_type]
            list_id = rec[:id]
            list_type_class = ModelReference.to_record_class_for_type list_type.singularize
            list_item = list_type_class.active.where(id: list_id).first

            if list_item && (list_item.send_status == 'not sent' || list_item.can_retry?)
              # Get the referenced record item (such as live contact record)
              ri = list_item.record_item no_exception: true
              # Set the data to nil to ensure template generation uses the item instead
              self.data = nil
              # If a record_item is referenced from the list item, use that as data instead
              self.item = ri || list_item
              # Force a current user to be the last user if one is not set
              item.current_user ||= for_item&.user || user
              pn = Formatter::Phone.format list_item.data, format: :unformatted, default_country_code: def_country_code
              recipient_sms_numbers = [pn]

              resp = generate_and_send recipient_sms_numbers: recipient_sms_numbers

              list_item.set_response list_item.user, resp

              # The final results is a list of recipient phone numbers
              recipient_data << list_item.data
            elsif list_item&.send_status == Messaging::NotificationSms::BadFormatMsg
              logger.info 'Recipient in list had bad format phone number. Will not attempt to resend'
            elsif list_item&.send_status == 'success'
              logger.info 'Recipient in list was already succesfully sent. Will not resend'
            elsif !list_item&.can_retry?
              logger.info 'Recipient previously failed but can not retry'
            elsif list_item&.send_status == 'sent'
              logger.info 'Recipient in list was already sent. Will not resend for some other reason'
            else
              logger.warn "A recipient list item did not exist (#{!!list_item}) or some other reason for not sending"
            end
          end

          self.recipient_data = recipient_data
        else
          generate_and_send
        end

        logger.info "Deliver now #{id}"
        update! status: StatusComplete

        # Once the notifications have been sent, fire the on_complete triggers
        if for_item
          for_item.current_user = for_item.user
          OptionConfigs::ActivityLogOptions.calc_save_triggers for_item, on_complete_config
        end

        logger.info "Handled item #{id}"
      rescue StandardError => e
        Rails.logger.warn "handle_notification_now job failed (may retry?): #{e}\n#{e.backtrace[0..20].join("\n")}"
        update! status: StatusFailed
        raise FphsException, "Exception captured in handle_notification_now: #{e}\n#{e.backtrace[0..20].join("\n")}"
      end
      # end
    end

    def generate_and_send(recipient_sms_numbers: nil)
      generate

      if is_email?
        NotificationMailer.send_message_notification(self, logger: logger).deliver_now
      elsif is_sms?
        sms = Messaging::NotificationSms.new
        sms.send_now(self, recipient_sms_numbers: recipient_sms_numbers, generated_text: generated_text,
                           importance: importance, logger: logger)
      else
        raise FphsException, "No recognized message type for message notification: #{message_type}"
      end
    end

    def is_sms?
      message_type&.to_sym == :sms
    end

    def is_email?
      message_type&.to_sym == :email
    end

    private

    def item_type_valid?
      res = item_type.safe_constantize
      errors.add :item_type, "is not a valid class name: '#{item_type}'" unless res
    end

    def content_template_specified?
      return if content_template_text || content_template_name

      errors.add :content_template_name, 'or content template text must be set'
    end
  end
end
