# frozen_string_literal: true

module Messaging
  class MessageNotification < ActiveRecord::Base
    # Set the max number of recipients for a message, to avoid an unexpected nasty error spamming the whole organization
    MaxRecipients = Settings::MaxNotificationRecipients
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
    validates :master, presence: true, if: :requires_master?
    # No validation on app_type, since external systems may use Rails based script to fire notifications
    # validates :app_type, presence: true
    # No minimum on recipient_user_ids, since recipient_data may be used instead
    validates :recipient_user_ids, length: { maximum: MaxRecipients }, if: :app_type
    validates :layout_template_name, presence: true

    # The type of message - either email or sms currently
    validates :message_type, presence: true
    validate :content_template_specified?
    validate :item_type_valid?, if: :app_type

    # We set recipient data within a callback rather than directly in the setter
    # for the recipient_user_ids, since the values being set are dependent on the message
    # type, and this may not be set at the point the recipient_user_ids= is called.
    # Before save we should have everything in place and validated.
    before_save :set_recipient_data

    before_save :set_from_email_address

    scope :unhandled, -> { where status: nil }
    scope :limited_index, -> { limit 50 }

    attr_accessor :generated_text, :disabled, :admin_id, :for_item, :on_complete_config, :ignore_no_recipients
    attr_writer :extra_substitutions_data, :batch_user

    #
    # Get a layout template by name and optionally message type
    # Useful as a quick check to see if a specific template has been defined before
    # instantiating a full MessageNotification
    def self.layout_template(name, message_type: :email)
      Admin::MessageTemplate.active.layout_templates.named name, type: message_type
    end

    #
    # The layout template instance for this notification
    def layout_template
      Admin::MessageTemplate.active.layout_templates.named layout_template_name, type: message_type
    end

    #
    # The content template instance for this notification
    def content_template
      Admin::MessageTemplate.active.content_templates.named content_template_name, type: message_type
    end

    #
    # Set the importance of the message, checking the value is valid
    # @param [String] value - one of ValidImportance (currently Promotional | Transactional)
    def importance=(value)
      value = value.to_s.capitalize
      raise FphsException, "Incorrect importance: #{value}" unless value.in?(ValidImportance)

      super(value)
    end

    #
    # Generate the message text from the templates and data
    # The instance is saved, to ensure the data and generated content is persisted.
    def generate(ignore_missing: false)
      data = self.data
      if data.blank?
        raise FphsException, 'Data is blank and item_type / item_id does not return an item' unless item

        data = Formatter::Substitution.setup_data item, for_item
        data[:_subject] = subject
        data[:extra_substitutions] = extra_substitutions_data

      end

      raise FphsException, "Layout template #{layout_template_name} was not found" unless layout_template

      if content_template_name
        raise FphsException, "Content template #{content_template_name} was not found" unless content_template
      elsif !content_template_text
        raise FphsException, 'Content template name or text must be set'
      end

      # We need to prevent conversion to html for all SMS
      markdown_to_html = if sms?
                           false
                         else
                           :force_markdown_to_html
                         end

      self.generated_text = layout_template.generate(content_template_name:,
                                                     content_template_text:,
                                                     data:,
                                                     ignore_missing:,
                                                     markdown_to_html:)

      self.generated_content = generated_text
      save!
    end

    #
    # Show the saved #generated_content or generate it dynamically now.
    # If an error occurs generating the content dynamically, a simple EXCEPTION
    # string is returned, to avoid crashing a viewing page.
    # @param [Boolean] ignore_missing
    # @return [String]
    def generate_view(ignore_missing: false)
      return generated_content if generated_content.present?

      generate(ignore_missing:)
    rescue FphsException => e
      "EXCEPTION: #{e}"
    end

    #
    # Set the values for recipient user ids.
    # If an array of User instances is provided, these are mapped to their ids for storage.
    # A before_save callback decides that if not empty then the user ids set #recipient_data
    # @param [Array{User | Integer}] users
    def recipient_user_ids=(users)
      reset_recipients!
      user_ids = users.map { |u| u.is_a?(User) ? u.id : u }
      super(user_ids)
    end

    def recipient_emails
      return @recipient_emails if @recipient_emails
      return unless email?

      @recipient_emails = if recipient_data && !recipient_user_ids&.present?
                            recipient_data
                          else
                            recipient_users_email
                          end
    end

    def recipient_emails=(emails)
      reset_recipients!
      self.recipient_data = emails
    end

    def recipient_sms_numbers
      return @recipient_sms_numbers if @recipient_sms_numbers
      return unless sms?

      @recipient_sms_numbers = if recipient_data && !recipient_user_ids&.present?
                                 recipient_data
                               else
                                 recipient_users_sms
                               end
    end

    def recipient_sms_numbers=(nums)
      reset_recipients!
      self.recipient_data = nums
    end

    #
    # Overlay the recipient_data data field attribute to convert incoming
    # array of hashes into array of JSON strings. Otherwise just leave the data as is
    # @param [Array{String | Hash}] data
    def recipient_data=(data)
      data = data.map(&:to_json) if data.is_a?(Array) && data.first.is_a?(Hash)
      @recipient_hash_from_data = nil
      super(data)
    end

    #
    # This overlays a varchar database field, which represents data in a YAML format.
    # Extra substitutions data is actually a hash that is provided so it can
    # be substituted into the message using substitutions like {{extra_substitutions.data1}}
    # @param [Hash | String] data - hash or YAML
    def extra_substitutions=(data)
      if data.is_a?(Hash)
        self.extra_substitutions_data = data
        data = data.to_yaml
      end

      super(data)
    end

    #
    # Set the from address for the email. This may be either a string,
    # or a hash as { address:, display_name: }
    # @param [String | Hash] email
    def from_user_email=(email)
      if email.is_a? Hash
        formatted = Mail::Address.new email[:address]
        formatted.display_name = email[:display_name]
        email = formatted.format
      end

      super(email)
    end

    #
    # Process this Messaging::MessageNotification record within a background job
    # Do not use a transaction, since we want successfully sent recipients to have a record saved so they
    # don't get hit again
    # @param [Logger] logger - logger to use from the background job, or the default Rails logger
    # @param [UserBase] for_item - typically an activity log item
    # @param [Hash] on_complete_config - the on_complete configuration from the activity log definition
    def handle_notification_now(logger: Rails.logger, for_item: nil, on_complete_config: {}, alt_batch_user: nil,
                                ignore_no_recipients: nil)
      logger.info "Handling item #{id}"
      update! status: StatusInProgress

      self.ignore_no_recipients ||= ignore_no_recipients
      self.for_item ||= for_item
      self.on_complete_config ||= on_complete_config
      self.batch_user ||= alt_batch_user

      # Check if recipient records have been set in the recipient_data (typically from SaveTriggers::Notify)
      # If not, we just have a list of emails or phones
      if recipient_hash_from_data
        generate_and_send_for_recipient_records
      else
        # Generate and send the same message to all the recipients
        generate_and_send
      end

      update! status: StatusComplete
      fire_item_on_complete_triggers
      logger.info "Handled item #{id}"
    rescue StandardError => e
      update! status: StatusFailed
      raise FphsException, "Exception captured in handle_notification_now: #{e}"
    end

    #
    # Generate the content from template and send to the recipients immediately.
    # The keyword argument recipient_sms_numbers may be set for SMS message type, to
    # override the #recipient_sms_numbers of the current instance.
    # @param [Array | nil] recipient_sms_numbers - optionally override numbers to send to
    def generate_and_send(recipient_sms_numbers: nil)
      generate

      if email?
        NotificationMailer.send_message_notification(self).deliver_now
      elsif sms?
        sms = Messaging::NotificationSms.new
        sms.send_now(self, recipient_sms_numbers:, generated_text:, ignore_no_recipients:,
                           importance:, logger:)
      else
        raise FphsException, "No recognized message type for message notification: #{message_type}"
      end
    end

    #
    # Is the message an sms?
    def sms?
      message_type&.to_sym == :sms
    end

    #
    # Is the message an email?
    def email?
      message_type&.to_sym == :email
    end

    def reset_recipients!
      @recipient_sms_numbers = nil
      @recipient_emails = nil
    end

    #
    # The message notification works with an underlying item (likely an activity log implementation)
    # Handle setting of the item and use of the actual class referenced
    # in the item_type / item_id attributes
    def item=(new_item)
      @item = new_item
      self.item_id = @item.id
      self.item_type = new_item.class.name.classify
    end

    #
    # The message notification works with an underlying item (likely an activity log implementation)
    # Handle getting the item and use of the actual class referenced
    # in the item_type / item_id attributes
    def item
      @item ||= item_class.where(id: item_id).first if item_class
    end

    #
    # The #recipient_data attribute can contain an array of emails, SMS numbers or JSON strings.
    # If it is an array of JSON strings and the JSON represents hashes with key 'list_type'
    # (based on checking the first one), map each JSON string to a Hash:
    #   {
    #     list_type: 'namespace__model_name',
    #     id: 'id from an instance of the list_type class',
    #     default_country_code: 'optional country code for numbers that don't specify them directly'
    #   }
    # @return [Array{Hash}] <description>
    def recipient_hash_from_data
      return @recipient_hash_from_data if @recipient_hash_from_data

      first_rec_data_json = recipient_data&.first
      return unless first_rec_data_json.is_a?(String)

      begin
        first_rec_data = JSON.parse(first_rec_data_json)
        return unless first_rec_data.is_a?(Hash) && first_rec_data['list_type']

        @recipient_hash_from_data = recipient_data.map { |r| JSON.parse(r).symbolize_keys }
      rescue StandardError
        nil
      end
    end

    private

    #
    # If we have been passed recipient records, use these to generate each message for sending
    def generate_and_send_for_recipient_records
      new_recipient_data = []
      recipient_hash_from_data.each do |rec|
        # Get the list item instance referenced by the list_type and id values
        list_item = list_item_for(rec[:list_type], rec[:id])

        if list_item && (list_item.send_status == 'not sent' || list_item.can_retry?)
          # Get the referenced record item from the list item (such as live contact record)
          record_item = list_item.record_item no_exception: true
          # If a record_item is referenced from the list item, use that as data instead
          self.item = record_item || list_item
          # Set the data to nil to ensure template generation uses the item
          self.data = nil
          # Force a current user to be the batch user, so that a single user can be set for access to any
          # external IDs, associated tables, etc, required for data substitutions.
          item.current_user = batch_user
          pn = Formatter::Phone.format list_item.data,
                                       format: :unformatted,
                                       default_country_code: rec[:default_country_code]
          recipient_sms_numbers = [pn]
          # Generate and send to this specific phone number with the data for this item
          resp = generate_and_send(recipient_sms_numbers:)

          list_item.set_response list_item.user, resp
          # Add the phone number to the recipient data hash
          new_recipient_data << rec.merge(data: list_item.data)
        else
          log_recipient_data_reason list_item
        end
      end

      self.recipient_data = new_recipient_data
    end

    #
    # Validation to check if the item type represents a valid class.
    # Sets error if the class name is invalid
    # @return [Boolean]
    def item_type_valid?
      res = item_type.safe_constantize
      errors.add :item_type, "is not a valid class name: '#{item_type}'" unless res
    end

    #
    # Validation to check if the content template text or name is set/
    # Sets error if not set
    # @return [Boolean]
    def content_template_specified?
      return if content_template_text || content_template_name

      errors.add :content_template_name, 'or content template text must be set'
    end

    #
    # All active user instances, based on the #recipient_user_ids
    # @return [<Type>] <description>
    def recipient_users
      User.active.where(id: recipient_user_ids).all
    end

    #
    # Returns all unique SMS numbers for the recipient_users
    # @return [Array{String}]
    def recipient_users_sms
      recipient_users
        .select { |u| u.contact_info&.sms_number&.present? }
        .map { |u| u.contact_info.sms_number }
        .uniq
    end

    #
    # Returns all unique email address for the recipient_users
    # @return [Array{String}]
    def recipient_users_email
      recipient_users.pluck(:email).uniq
    end

    #
    # Typically called in a before_save callback,
    # set the #recipient_data from the recipient users
    # according to the message type being an email or sms
    def set_recipient_data
      return if recipient_data
      return unless recipient_user_ids&.present?

      self.recipient_data = if email?
                              recipient_users_email
                            elsif sms?
                              recipient_users_sms
                            end
    end

    #
    # Typically called in a before_save callback,
    # set the #from_user_email address if it is not already set,
    # using either the Settings (typically) or the owner user (if set)
    def set_from_email_address
      self.from_user_email ||= Settings::NotificationsFromEmail || user&.email
    end

    #
    # The hash data representation of #extra_substitutions
    # @return [Hash]
    def extra_substitutions_data
      return @extra_substitutions_data if @extra_substitutions_data
      return unless extra_substitutions

      @extra_substitutions_data = YAML.safe_load(extra_substitutions, permitted_classes: [Symbol])
    end

    #
    # The class of the underlying item, from the #item_type string attribute
    def item_class
      item_type&.classify&.constantize
    end

    #
    # Get the instance referred to by list type and id
    # @param [String] list_type
    # @param [Integer] list_id
    # @return [UserBase]
    def list_item_for(list_type, list_id)
      list_type_class = ModelReference.to_record_class_for_type list_type.singularize
      list_type_class.active.where(id: list_id).first
    end

    #
    # Once the notifications have been sent, fire the on_complete triggers
    def fire_item_on_complete_triggers
      return unless for_item && on_complete_config.present?

      for_item.current_user = batch_user
      OptionConfigs::ActivityLogOptions.calc_triggers for_item, on_complete_config
    end

    def batch_user
      return @batch_user if @batch_user

      @batch_user = User.batch_user
      unless @batch_user
        raise FphsException,
              "User is not found for BatchUserEmail '#{Settings::BatchUserEmail}' for message notifications"
      end

      @batch_user.app_type = Settings.bulk_msg_app
      @batch_user
    end

    #
    # Log the result of recipient data processing
    # @param [UserBase] list_item
    def log_recipient_data_reason(list_item)
      if list_item&.send_status == Messaging::NotificationSms::BadFormatMsg
        logger.info 'Recipient in list had bad format phone number. Will not attempt to resend'
      elsif list_item&.send_status == 'success'
        logger.info 'Recipient in list was already successfully sent. Will not resend'
      elsif !list_item&.can_retry?
        logger.info 'Recipient previously failed but can not retry'
      elsif list_item&.send_status == 'sent'
        logger.info 'Recipient in list was already sent. Will not resend for some other reason'
      else
        logger.warn "A recipient list item did not exist (#{!!list_item}) or some other reason for not sending"
      end
    end

    #
    # Should a new record require a master to be set?
    def requires_master?
      return app_type unless item_class.respond_to?(:no_master_association)

      app_type && !item_class.no_master_association
    end
  end
end
