class SaveTriggers::Notify < SaveTriggers::SaveTriggersBase

  attr_accessor :model_defs, :role, :users, :layout_template, :content_template, :message_type, :subject, :receiving_user_ids

  def self.config_def if_extras: {}
    [
      {
        type: "email|sms",
        role: "(optional) role name to notify - or reference like {this: {user_id: return_value} }",
        users: "(optional) list of users to notify - or reference this: {this: {role_names: return_value} }",
        layout_template: "name of layout template",
        content_template: "name of content template",
        subject: "subject text",
        if: if_extras
      }
    ]
  end

  def initialize config, item
    super

    @model_defs = config
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

  end

  def perform

    @model_defs.each do |config|

      # We calculate the conditional if inside each item, rather than relying
      # on the outer processing in ExtraLogType#calc_save_trigger_if
      if config[:if]
        ca = ConditionalActions.new config[:if], @item
        next unless ca.calc_action_if
      end


      @role = config[:role]
      @users = config[:users]
      if @role
        role_name = calc_field_or_return(@role)
        @receiving_user_ids = Admin::UserRole.active_user_ids role_name: role_name, app_type: @user.app_type
      elsif @users
        user_ids = calc_field_or_return(@users)
        @receiving_user_ids = User.where(id: user_ids).active.pluck(:id)
      else
        raise FphsException.new "either role or users must be specified in save_trigger: notify: role: ..."
      end
      @layout_template = config[:layout_template]
      @content_template = config[:content_template]
      @message_type = config[:type]
      @subject = config[:subject]



      if @receiving_user_ids.length == 0
        Rails.logger.warn "No users assigned to role #{@role} in #{self.class.name}"
        return
      end

      mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@receiving_user_ids], layout_template_name: @layout_template,
      content_template_name: @content_template, item_type: @item.class.name, item_id: @item.id, master_id: @item.master_id, message_type: @message_type, subject: @subject,
      role_name: role_name

      HandleMessageNotificationJob.perform_later(mn)

    end

  end

  def calc_field_or_return cond
    if cond.is_a? Hash
      action_conf = cond
      ca = ConditionalActions.new action_conf, item
      return ca.get_this_val
    else
      return cond
    end
  end



end
