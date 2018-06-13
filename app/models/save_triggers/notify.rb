class SaveTriggers::Notify < SaveTriggers::SaveTriggersBase

  attr_accessor :role, :layout_template, :content_template, :message_type, :subject, :receiving_user_ids

  def self.config_def if_extras: {}
    {
      type: "email",
      role: "role name to notify",
      layout_template: "name of layout template",
      content_template: "name of content template",
      subject: "subject text",
      if: if_extras
    }
  end

  def initialize config, item
    super

    @role = config[:role]
    raise FphsException.new "role must be specified in save_trigger: notify: role: ..." unless @role
    @layout_template = config[:layout_template]
    @content_template = config[:content_template]
    @message_type = config[:type]
    @subject = config[:subject]

    @receiving_user_ids = Admin::UserRole.active_user_ids role_name: @role, app_type: @user.app_type

  end

  def perform
    if @receiving_user_ids.length == 0
      Rails.logger.warn "No users assigned to role #{@role} in #{self.class.name}"
      return
    end

    mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@receiving_user_ids], layout_template_name: @layout_template,
    content_template_name: @content_template, item_type: @item.class.name, item_id: @item.id, master_id: @item.master_id, message_type: @message_type

    HandleMessageNotificationJob.perform_later(mn)
  end



end
