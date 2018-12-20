class Messaging::MessageNotification < ActiveRecord::Base



  # Set the max number of recipients for a message, to avoid an unexpected nasty error spamming the whole organization
  MaxRecipients = 20
  StatusComplete = 'complete'
  StatusInProgress = 'in progress'
  StatusFailed = 'failed'

  include WorksWithItem

  belongs_to :app_type, class_name: 'Admin::AppType'
  belongs_to :user
  belongs_to :master
  # Even external systems that use a Rails based script to fire notifications must use a real user
  validates :user, presence: true, if: :app_type
  validates :master, presence: true, if: :app_type
  # No validation on app_type, since external systems may use Rails based script to fire notifications
  # validates :app_type, presence: true
  # No minimum on recipient_user_ids, since recipient_emails may be used instead
  validates :recipient_user_ids, length: {maximum: MaxRecipients}, if: :app_type
  validates :layout_template_name, presence: true
  validates :content_template_name, presence: true
  validates :message_type, presence: true
  validate :item_type_valid?, if: :app_type

  scope :unhandled, -> { where status: nil }
  scope :index, -> { limit 20 }

  attr_accessor :generated_text, :disabled, :admin_id

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
    item_type.classify.constantize if item_type
  end

  def item
    @item ||= item_class.where(id: item_id).first if item_class
  end

  def item= new_item
    @item = new_item
    self.item_id = @item.id
    self.item_type = new_item.class.name.classify
  end


  # Generate the message text from the templates and data
  def generate

    data = self.data
    if data.blank?
      raise FphsException.new "Data is blank and item_type / item_id does not return an item" unless item

      data = item.attributes.dup

      # if the referenced item has its own referenced item (much like an activity log might), then get it
      if item.respond_to?(:item) && item.item.respond_to?(:attributes)
        data[:item] = item.item.attributes
      end

      if item.respond_to? :user
        data[:user_email] = user.email
      end

      self.save!
    end

    raise FphsException.new "Layout template #{layout_template_name} was not found" unless layout_template
    raise FphsException.new "Content template #{content_template_name} was not found" unless content_template

    self.generated_text = layout_template.generate content_template_name: content_template_name, data: data

  end

  def generate_view
    begin
      generate
    rescue FphsException => e
      "EXCEPTION: #{e}"
    end
  end

  def recipient_users
    User.active.where(id: recipient_user_ids).all
  end

  def recipient_emails
    res = super()
    return res if res
    res = recipient_users.pluck(:email)
    self.recipient_emails = res.uniq
    self.save
    res
  end

  def recipient_sms_numbers
    return @recipient_numbers if @recipient_numbers
    recipient_users.reject {|u| !u.contact_info || u.contact_info.sms_number.blank? }.map {|u| u.contact_info&.sms_number }.uniq
  end

  def recipient_sms_numbers= nums
    @recipient_numbers = nums
  end


  def from_user_email
    res = super()
    return res if res
    res = Settings::NotificationsFromEmail || self.user&.email
    self.from_user_email = res
    self.save
    res
  end


  # Process this Messaging::MessageNotification record
  def handle_notification_now logger: Rails.logger

    logger.info "Handling item #{self.id}"
    self.update! status: StatusInProgress

    Messaging::MessageNotification.transaction do
      begin
        self.generate

        if message_type&.to_sym == :email
          NotificationMailer.send_message_notification(self, logger: logger).deliver_now
        elsif message_type&.to_sym == :sms
          Messaging::NotificationSms.send_now(self, logger: logger)
        else
          raise FphsException.new "No recognized message type for message notification: #{message_type}"
        end
        logger.info "Deliver now #{self.id}"
        self.update! status: StatusComplete
        logger.info "Handled item #{self.id}"
      rescue => e
        Rails.logger.warn "handle_notification_now job failed (may retry?): #{e}\n#{e.backtrace[0..20].join("\n")}"
        self.update! status: StatusFailed
        raise FphsException.new "Exception captured in handle_notification_now: #{e}\n#{e.backtrace[0..20].join("\n")}"
      end
    end
  end

  private

    def item_type_valid?

      res = item_type.constantize rescue nil
      errors.add :item_type, "is not a valid class name: '#{item_type}'" unless res

    end
end
