class MessageNotification < ActiveRecord::Base



  # Set the max number of recipients for a message, to avoid an unexpected nasty error spamming the whole organization
  MaxRecipients = 10
  StatusComplete = 'complete'
  StatusInProgress = 'in progress'
  StatusFailed = 'failed'

  include WorksWithItem

  belongs_to :app_type
  belongs_to :user
  belongs_to :master

  validates :user, presence: true
  validates :app_type, presence: true
  validates :master, presence: true
  validates :recipient_user_ids, length: {minimum: 1, maximum: MaxRecipients}
  validates :layout_template_name, presence: true
  validates :content_template_name, presence: true
  validates :message_type, presence: true
  validate :item_type_valid?

  scope :unhandled, -> { where status: nil }
  scope :index, -> { limit 10 }

  attr_accessor :generated_text, :disabled, :admin_id

  def layout_template
    MessageTemplate.active.layout_templates.named layout_template_name
  end

  def content_template
    MessageTemplate.active.content_templates.named content_template_name
  end

  # The message notification works with an underlying item (likely an activity log implementation)
  # Handle getting and setting of the item and use of the actual class referenced
  # in the item_type / item_id attributes
  def item_class
    item_type.classify.constantize
  end

  def item
    @item ||= item_class.where(id: item_id).first
  end

  def item= new_item
    @item = new_item
    self.item_id = @item.id
    self.item_type = new_item.class.name.classify
  end


  # Generate the message text from the templates and data
  def generate

    if data.blank?
      data = item.attributes

      # if the referenced item has its own referenced item (much like an activity log might), then get it
      if item.respond_to? :item
        data[:item] = item.item.attributes
      end

      if item.respond_to? :user
        data[:user_email] = user.email
      end

      self.save!
    end

    self.generated_text = layout_template.generate content_template_name: content_template_name, data: data

  end

  def recipient_users
    User.active.where(id: recipient_user_ids).all
  end

  def recipient_emails
    recipient_users.pluck(:email)
  end

  def from_user_email
    self.user.email
  end

  # Handle new notification records that may have been added by a DB trigger
  # Run each message notification in a job, to avoid blocking
  def self.handle_notification_records item

    mns = MessageNotification.where(item_id: item.id, item_type: item.class.name, status: nil).all

    logger.info "Got message notifications #{mns.pluck(:id)}"

    return if mns.length == 0

    logger.info "Creating a job for each of #{mns.pluck(:id)}"
    # Create a background job for each message notification
    mns.each do |mn|
      logger.info "Creating a new job for #{mn.id}"
      HandleMessageNotificationJob.perform_later(mn)
    end

  end

  # Process this MessageNotification record
  def handle_notification_now logger: Rails.logger

    logger.info "Handling item #{self.id}"
    self.update! status: StatusInProgress

    MessageNotification.transaction do
      begin
        email_body = self.generate

        NotificationMailer.send_message_notification(self, logger: logger).deliver_now
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
      errors.add :item_type, 'is not a valid class name' unless res

    end
end
