class SaveTriggers::Notify < SaveTriggers::SaveTriggersBase

  attr_accessor :role, :users, :layout_template, :content_template, :message_type, :subject, :receiving_user_ids

  def self.config_def if_extras: {}
    {
      type: "email",
      role: "(optional) role name to notify",
      users: "(optional) list of users to notify",
      layout_template: "name of layout template",
      content_template: "name of content template",
      subject: "subject text",
      if: if_extras
    }
  end

  def initialize config, item
    super

    @role = config[:role]
    @users = config[:users]
    if @role
      if @role.is_a? Hash
        action_conf = @role
        ca = ConditionalActions.new action_conf, item
        role_name = ca.get_this_val
      else
        role_name = @role
      end
      @receiving_user_ids = Admin::UserRole.active_user_ids role_name: role_name, app_type: @user.app_type
    elsif
      user_ids = @users
      @receiving_user_ids = User.where(id: user_ids).active.pluck(:id)
    else
      raise FphsException.new "either role or users must be specified in save_trigger: notify: role: ..."
    end
    @layout_template = config[:layout_template]
    @content_template = config[:content_template]
    @message_type = config[:type]
    @subject = config[:subject]


  end

  def perform
    if @receiving_user_ids.length == 0
      Rails.logger.warn "No users assigned to role #{@role} in #{self.class.name}"
      return
    end

    mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@receiving_user_ids], layout_template_name: @layout_template,
    content_template_name: @content_template, item_type: @item.class.name, item_id: @item.id, master_id: @item.master_id, message_type: @message_type, subject: @subject

    HandleMessageNotificationJob.perform_later(mn)
  end



end
