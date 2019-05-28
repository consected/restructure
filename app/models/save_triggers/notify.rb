class SaveTriggers::Notify < SaveTriggers::SaveTriggersBase

  attr_accessor :model_defs, :role, :users, :layout_template, :content_template, :content_template_text, :message_type, :subject,
                :receiving_user_ids, :phones, :emails, :default_country_code, :when

  def self.config_def if_extras: {}
    [
      {
        type: "email|sms",
        role: "(optional) role name to notify - or reference like {this: {user_id: return_value} }",
        users: "(optional) list of users to notify - or reference like {this: {role_names: return_value} }",
        phones: "(optional) list of phone numbers to notify - or reference like {this: {phone_numbers: return_value} }",
        default_country_code: "(optional) country code for SMS numbers, if they are not otherwise specified",
        layout_template: "name of layout template",
        content_template: "name of content template",
        content_template_text: "alternative content template text",
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
      @phones = config[:phones]
      @emails = config[:emails]
      @default_country_code = config[:default_country_code]
      @when = config[:when]

      if @role
        role_name = calc_field_or_return(@role)
        @receiving_user_ids = Admin::UserRole.active_user_ids role_name: role_name, app_type: @user.app_type
      elsif @users
        user_ids = calc_field_or_return(@users)
        @receiving_user_ids = User.where(id: user_ids).active.pluck(:id)
      elsif @phones
        force_phones = calc_field_or_return(@phones)

        @phones = force_phones = force_phones.map {|p|
          Formatter::Phone.format p, format: :unformatted, default_country_code: @default_country_code
        }

      elsif @emails
        force_emails = calc_field_or_return(@emails)
      else
        raise FphsException.new "role, users or phones must be specified in save_trigger: notify: role: ..."
      end

      if (!@receiving_user_ids || @receiving_user_ids.length == 0) && !force_phones && !force_emails
        Rails.logger.warn "No users assigned to role #{@role} in #{self.class.name}"
        return
      end

      if @item.respond_to?(:filter_notifications)
        @receiving_user_ids = @item.filter_notifications @receiving_user_ids
        if @receiving_user_ids.length == 0
          Rails.logger.info "No users assigned to role #{@role} after filtering"
          return
        end
      end

      if @when
        set_when = {}
        if @when[:wait]
          set_when[:wait_until] = FieldDefaults.calculate_default nil, @when[:wait], from_when: DateTime.now
        elsif @when[:wait_until]
          set_when[:wait_until] = FieldDefaults.calculate_default nil, @when[:wait_until], :datetime_type
        end
        @when = set_when
      end

      @layout_template = config[:layout_template]
      @content_template = config[:content_template]
      @content_template_text = config[:content_template_text]
      @message_type = config[:type]
      @subject = config[:subject]


      mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@receiving_user_ids], layout_template_name: @layout_template,
      content_template_name: @content_template, content_template_text: @content_template_text, item_type: @item.class.name, item_id: @item.id, master_id: @item.master_id, message_type: @message_type, subject: @subject,
      role_name: role_name, recipient_sms_numbers: force_phones, recipient_emails: force_emails

      job = HandleMessageNotificationJob

      if set_when
        job = job.set(set_when)
      end

      job.perform_later(mn)

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
