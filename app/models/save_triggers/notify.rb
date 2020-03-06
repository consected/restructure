class SaveTriggers::Notify < SaveTriggers::SaveTriggersBase

  attr_accessor :model_defs, :role, :users, :layout_template, :content_template, :content_template_text, :message_type, :subject,
                :receiving_user_ids, :phones, :emails, :default_country_code, :when, :importance, :extra_substitutions

  def self.config_def if_extras: {}
    [
      {
        type: "email|sms",
        role: "(optional) role name(s) to notify - or reference like {this: {user_id: return_value} }",
        users: "(optional) list of users to notify - or reference like {this: {phone_numbers: return_value} }",
        phones: "(optional) list of phone numbers to notify - or reference like {this: {role_names: return_value} }",
        default_country_code: "(optional) country code for SMS numbers, if they are not otherwise specified",
        layout_template: "name of layout template",
        content_template: "name of content template",
        content_template_text: "alternative content template text",
        subject: "subject text",
        extra_substitutions: {
          data1: 'fixed data item to be substituted into the message in {{extra_substitutions.data1}}'
        },
        importance: "transactional (default) | promotional",
        when: {
          wait_until: '(optional) ISO date or {date:..., time..., zone:... } where zone is one specified in MAPPINGS @ https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html',
          wait: 'n seconds|minutes|hours|days|weeks|months|years'
        },
        if: if_extras
      }
    ]
  end

  # If we are running in production the the queue adapter will not be :inline
  # We can use future processing
  # In dev, debug and test we may want to use inline processing, which does not allow a future date to be set
  def self.allow_future_processing
    Rails.configuration.active_job.queue_adapter != :inline
  end

  def initialize config, item
    super

    @model_defs = config.deep_dup
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
      @phone_records = config[:phone_records]
      @list_type = config[:list_type]
      @emails = config[:emails]
      @default_country_code = config[:default_country_code]
      @when = config[:when]
      @layout_template = config[:layout_template]
      @content_template = config[:content_template]
      @content_template_text = config[:content_template_text]
      @message_type = config[:type]
      @subject = config[:subject]
      @importance = config[:importance]
      @extra_substitutions = config[:extra_substitutions]

      if @role || @users
        # Allow both role and users to be specified
        @receiving_user_ids = []

        if @role

          @role = @role.reject(&:blank?) if @role.is_a? Array

          role_name = calc_field_or_return(@role)

          role_name = role_name.reject(&:blank?) if role_name.is_a? Array

          @receiving_user_ids += Admin::UserRole.active_user_ids role_name: role_name, app_type: @user.app_type
        end

        if @users
          if @users.is_a? Array
            @users = @users.reject(&:blank?)
          end
          user_ids = calc_field_or_return(@users)
          @receiving_user_ids += User.where(id: user_ids).active.pluck(:id)
        end

        @receiving_user_ids.uniq!

      elsif @phones
        force_phones = calc_field_or_return(@phones)

        @phones = force_phones = force_phones.map {|p|
          Formatter::Phone.format p, format: :unformatted, default_country_code: @default_country_code, current_user: @item.user
        }
      elsif @phone_records

        ids = calc_field_or_return(@phone_records)
        raise FphsException.new "no recipients were found in the list" if ids.nil? || ids.length == 0

        list_type_class = ModelReference.to_record_class_for_type @list_type.singularize
        recs = list_type_class.where id: ids

        force_recip_recs = recs.map{|rec| {list_type: @list_type, id: rec.id, default_country_code: @default_country_code}.to_json }
      elsif @emails
        force_emails = calc_field_or_return(@emails)
      else
        raise FphsException.new "role, users or phones must be specified in save_trigger: notify: role: ..."
      end

      if @importance
        force_importance = calc_field_or_return(@importance)
      end

      if (!@receiving_user_ids || @receiving_user_ids.length == 0) && !force_phones && !force_emails && !force_recip_recs
        Rails.logger.warn "No recipients based on role: #{@role}, users or specified phones/emails in #{self.class.name}"
        return
      end

      if @item.respond_to?(:filter_notifications)
        @receiving_user_ids = @item.filter_notifications @receiving_user_ids
        if @receiving_user_ids.length == 0
          Rails.logger.info "No recipients after filtering"
          return
        end
      end

      if @when
        set_when = {}

        if @when[:wait]
          set_when[:wait_until] = FieldDefaults.calculate_default nil, @when[:wait], from_when: DateTime.now
        elsif @when[:wait_until]
          wu = @when[:wait_until]

          if wu.is_a? Hash
            w = {
              date: calc_field_or_return(wu[:date]),
              time: calc_field_or_return(wu[:time]),
              zone: calc_field_or_return(wu[:zone]) || :user
            }
            wdate = Formatter::DateTime.format(w, utc: true, iso: true, current_user: @item.user)
          else
            wdate = wu
          end

          if wdate
            set_when[:wait_until] = FieldDefaults.calculate_default nil, wdate, :datetime_type
          else
            set_when = nil
          end
        end
        @when = set_when
      end

      if @content_template_text.is_a? Hash
        @content_template_text = calc_field_or_return(@content_template_text)
      end

      if @subject
        @subject = Admin::MessageTemplate.substitute(@subject, data: @item, tag_subs: nil, ignore_missing: true)
      end

      if @extra_substitutions
        @extra_substitutions.each do |k,v|
          @extra_substitutions[k] = Admin::MessageTemplate.substitute(v, data: @item, tag_subs: nil, ignore_missing: true)
        end
      end

      setup_data = {
        app_type: @user.app_type, user: @user,
        recipient_user_ids: [@receiving_user_ids], layout_template_name: @layout_template,
        content_template_name: @content_template, content_template_text: @content_template_text,
        item_type: @item.class.name, item_id: @item.id, master_id: @item.master_id, message_type: @message_type, subject: @subject,
        role_name: role_name
      }

      setup_data[:recipient_sms_numbers] = force_phones if force_phones
      setup_data[:recipient_emails] = force_emails if force_emails
      setup_data[:recipient_data] = force_recip_recs if force_recip_recs
      setup_data[:importance] = force_importance if force_importance
      setup_data[:extra_substitutions] = @extra_substitutions

      mn = Messaging::MessageNotification.create! setup_data

      # Queue the job.
      job = HandleMessageNotificationJob
      # For testing and debugging mostly, allow this to run immediately inline
      job = job.set(set_when) if set_when && self.class.allow_future_processing
      # Pass in the MessageNotification as the main object
      # for_item is the ActivityLog instance that was triggered on save
      # Also pass the on_complete configuration to follow up after the main job processing completes
      res = job.perform_later(mn, for_item: @item, on_complete_config: config[:on_complete])

      if @item.respond_to?(:background_job_ref) && res&.provider_job
        @item.background_job_ref = "#{res.provider_job.class.name.ns_underscore}%#{res.provider_job.id}"
        @item.save
      end

    end

  end

  def calc_field_or_return cond
    ConditionalActions.calc_field_or_return cond, item
  end



end
