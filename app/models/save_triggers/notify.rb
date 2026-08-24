# frozen_string_literal: true

class SaveTriggers::Notify < SaveTriggers::SaveTriggersBase
  attr_accessor :model_defs, :role, :users, :layout_template, :message_type,
                :receiving_user_ids, :phones, :emails, :default_country_code, :job,
                :from_user_email

  def self.config_def(if_extras: {}); end

  # If we are running in production the the queue adapter will not be :inline
  # We can use future processing
  # In dev, debug and test we may want to use inline processing, which does not allow a future date to be set
  def self.allow_future_processing
    Rails.configuration.active_job.queue_adapter != :inline
  end

  def initialize(config, item)
    super

    @model_defs = self.config.deep_dup
    @model_defs = [@model_defs] unless @model_defs.is_a? Array
  end

  #
  # Iterate through each configuration to handle notifications if
  # defined conditions are met.
  # Setup the notification from the configuration and schedule it to run
  # in the background, either immediately or in the future
  def perform
    @item.save_trigger_results['notify_messages'] ||= []
    @item.save_trigger_results['notify_results'] ||= []
    @item.save_trigger_results['notify_errors'] ||= []

    @model_defs.each do |config|
      init_attribs config

      unless run_this?
        @item.save_trigger_results['notify_errors'] << nil
        @item.save_trigger_results['notify_results'] << false
        next
      end

      if @role || @users
        setup_role_and_users
      elsif @phones
        setup_phones
      elsif @phone_records
        setup_recipient_data
      elsif @emails
        setup_emails
      else
        raise FphsException, 'role, users, emails or phones must be specified in save_trigger: notify: role: ...'
      end

      if !@receiving_user_ids&.present? && !@force_phones && !@force_emails && !@force_recip_recs
        msg = "No recipients based on role: #{@role}, users or specified phones/emails in #{self.class.name} (user: #{resolve_user.email}, app_type: #{resolve_app_type&.id})"
        Rails.logger.warn msg
        @item.save_trigger_results['notify_results'] << false
        @item.save_trigger_results['notify_errors'] << msg
        next
      end

      if filter_notifications && @receiving_user_ids.empty?
        msg = 'No recipients after filtering'
        Rails.logger.info msg
        @item.save_trigger_results['notify_results'] << false
        @item.save_trigger_results['notify_errors'] << msg
        next
      end

      new_mn = create_message_notification_or_record_error
      next unless new_mn

      res = queue_job
      @item.save_trigger_results['notify_messages'] << new_mn
      @item.save_trigger_results['notify_results'] << true
      @item.save_trigger_results['notify_errors'] << nil

      next unless @item.respond_to?(:background_job_ref) && res&.provider_job

      @item.set_background_job_ref res
      @item.save
    end
  end

  private

  def init_attribs(config)
    @config = config
    @role = config[:role]
    @users = config[:users]
    @phones = config[:phones]
    @phone_records = config[:phone_records]
    @list_type = config[:list_type]
    @emails = config[:emails]
    @default_country_code = config[:default_country_code]
    @layout_template = config[:layout_template]
    @on_complete = config[:on_complete] || @on_complete_triggers
    @from_user_email = config[:from_user_email]
    @ignore_no_recipients = config[:ignore_no_recipients]
    # app_type/user accept a literal id/name, a {{substitution}}, or a conditional
    # Hash reference (e.g. {this: {field: return_value}}) - resolved here via
    # FieldDefaults before being passed to the id/name lookups below.
    @config_app_type = FieldDefaults.calculate_default(@item, config[:app_type], allow_nil: true, ignore_missing: true)
    @config_user = FieldDefaults.calculate_default(@item, config[:user], allow_nil: true, ignore_missing: true)

    @message_type = config[:type]
    @run_if = config[:if]
    @alt_batch_user = DynamicModel.user_for_conf_snippet({ user: @config_user, app_type: @config_app_type })

    # Clear memos for the following
    @extra_substitutions = nil
    @subject = nil
    @content_template_text = nil
    @importance = nil
  end

  #
  # Should the configured notification be run?
  # If config[:if] is not set or evaluates to true in a conditional action calculation
  # then run it. Otherwise don't.
  # @param [<Type>] _config <description>
  # @return [<Type>] <description>
  def run_this?
    return true unless @run_if

    ca = ConditionalActions.new @run_if, @item
    ca.calc_action_if
  end

  def email?
    @message_type.to_s == 'email'
  end

  def resolve_app_type
    if @config_app_type.present?
      Admin::AppType.find_active_by_name_or_id(@config_app_type, only_active_on_server: true)
    else
      @user.app_type
    end
  end

  def resolve_user
    @alt_batch_user || @user
  end

  #
  # Set up the roles and users to get a list of receiving user IDs
  def setup_role_and_users
    # Allow both role and users to be specified
    @receiving_user_ids = []

    if @role

      @role = @role.reject(&:blank?) if @role.is_a? Array
      @role_name = calc_field_or_return(@role)
      @role_name = @role_name.reject(&:blank?) if @role_name.is_a? Array

      @receiving_user_ids += Admin::UserRole.active_user_ids role_name: @role_name, app_type: resolve_app_type
    end

    if @users
      @users = @users.reject(&:blank?) if @users.is_a? Array
      user_ids = calc_field_or_return(@users)
      @receiving_user_ids += User.where(id: user_ids).active.pluck(:id)
    end

    @receiving_user_ids.uniq!

    # Clean up user list to remove users that are set to no-send emails (if an email is being sent)
    # or are template users
    rusers = User.active.where(id: @receiving_user_ids)
    rusers = rusers.reject { |u| u.a_template_or_batch_user? || (email? && u.do_not_email) }
    @receiving_user_ids = rusers.map(&:id)
  end

  #
  # Set up the phones to get a list of recipient phone numbers
  # Supports literal strings, template substitutions `{{field}}`, and conditional action hashes.
  # Can also be an array containing any combination of strings, substitutions and hashes.
  def setup_phones
    @force_phones = Array(calc_field_or_return(@phones)).map { |p| calc_field_or_return(p) }.compact

    @phones = @force_phones = @force_phones.map do |p|
      Formatter::Phone.format p, format: :unformatted,
                                 default_country_code: @default_country_code,
                                 current_user: @item.user
    end
  end

  def setup_recipient_data
    ids = calc_field_or_return(@phone_records)
    raise FphsException, 'no recipients were found in the list' if ids.nil? || ids.empty?

    list_type_class = ModelReference.to_record_class_for_type @list_type.singularize
    recs = list_type_class.where id: ids

    @force_recip_recs = recs.map do |rec|
      {
        list_type: @list_type,
        id: rec.id,
        default_country_code: @default_country_code
      }
    end
  end

  #
  # Set up the emails to get a list of recipient email addresses
  # Supports literal strings, template substitutions `{{field}}`, and conditional action hashes.
  # Can also be an array containing any combination of strings, substitutions and hashes.
  def setup_emails
    @force_emails = Array(calc_field_or_return(@emails)).map { |e| calc_field_or_return(e) }.compact
  end

  def filter_notifications
    return unless @item.respond_to?(:filter_notifications)

    @receiving_user_ids = @item.filter_notifications @receiving_user_ids
  end

  #
  # When to run the background notification, set by:
  #   when:
  #     wait:
  # or
  #   when:
  #     wait_until:
  #
  # The wait: option takes a calculation string, like "+1 day",
  # to be evaluated from the current date time.
  # The wait_until: option takes a
  # specific date / time to wait until, either as a string, or a hash of {date:, time:, zone: }
  # @return [<Type>] <description>
  def run_when
    return @run_when if @done_when

    @done_when = true

    @run_when = @config[:when]
    return unless @run_when

    set_when = {}

    if @run_when[:wait]
      set_when[:wait_until] = FieldDefaults.calculate_default nil, @run_when[:wait], from_when: DateTime.now
    elsif @run_when[:wait_until]
      wait_until = @run_when[:wait_until]

      if wait_until.is_a? Hash
        w = {
          date: calc_field_or_return(wait_until[:date]),
          time: calc_field_or_return(wait_until[:time]),
          zone: calc_field_or_return(wait_until[:zone]) || :user
        }
        wdate = Formatter::DateTime.format(w, utc: true, iso: true, keep_date: true,
                                              current_user: @item.current_user || @item.user)
      else
        wdate = wait_until
      end

      if wdate
        set_when[:wait_until] = FieldDefaults.calculate_default nil, wdate, :datetime_type
      else
        set_when = nil
      end
    end
    @run_when = set_when
  end

  #
  # The content template name to use to retrieve the actual text for the notification message
  # @return [String | nil]
  def content_template
    config[:content_template]
  end

  #
  # The full content template text to use for the message,
  # specified by config[:content_template_text]
  # If a hash is specified then the text will be retreived using a conditional action.
  # If the value is a string, substitutions will be performed. When the message is sent,
  # further substitutions will be performed to render the final message.
  # @return [String | nil]
  def content_template_text
    @content_template_text ||= calc_field_or_return(@config[:content_template_text])
    # return @content_template_text if @content_template_text

    # cond = @config[:content_template_text]
    # cond = ConditionalActions.new(cond, item).get_this_val if cond.is_a? Hash

    # @content_template_text = cond
  end

  #
  # The message subject text, which may include {{curly}} substitutions
  # @return [String]
  def subject
    return @subject if @subject

    @subject = config[:subject]
    return unless @subject

    @subject = Formatter::Substitution.substitute(@subject, data: @item, tag_subs: nil, ignore_missing: true)
  end

  #
  # Extra substitutions are defined by config[:extra_substitutions], to provide a hash that is
  # to be substituted into the message using substitutions like {{extra_substitutions.data1}}
  # Data within the extra substitutions is substituted from the item, so may also contain its own
  # {{curly}} substitutions, set at the time the notification is created, not at the time it is sent.
  # If a calendar_invite config is present, its values are resolved and merged into
  # extra_substitutions[:calendar_invite] for storage on the MessageNotification record.
  # @return [Hash | nil]
  def extra_substitutions
    return @extra_substitutions if @extra_substitutions

    @extra_substitutions = config[:extra_substitutions] || {}

    @extra_substitutions.each do |k, v|
      next unless v.is_a?(String)

      @extra_substitutions[k] = substitute_from_item(v)
    end

    merge_calendar_invite_into_extra_substitutions
    merge_attachments_into_extra_substitutions

    @extra_substitutions = nil if @extra_substitutions.blank?
    @extra_substitutions
  end

  #
  # Parse the calendar_invite config option, resolve substitutions in all values,
  # and merge the resolved hash into extra_substitutions[:calendar_invite].
  # Values support {{curly}} substitutions and conditional action hashes.
  # @return [void]
  def merge_calendar_invite_into_extra_substitutions
    cal_config = config[:calendar_invite]
    return unless cal_config

    resolved = cal_config.to_h do |k, v|
      [k.to_s, substitute_from_item(v)]
    end

    @extra_substitutions[:calendar_invite] = resolved
  end

  #
  # Parse the attachments config option, resolve substitutions in all values,
  # and merge the resolved array into extra_substitutions[:attachments].
  # Each attachment entry is a hash with container_id, path, and file_name keys.
  # Values support {{curly}} substitutions and conditional action hashes
  # (e.g. {this: {field: return_value}}).
  # @return [void]
  def merge_attachments_into_extra_substitutions
    att_config = config[:attachments]
    return unless att_config

    resolved = att_config.map do |entry|
      entry.to_h do |k, v|
        [k.to_s, substitute_from_item(v)]
      end
    end

    @extra_substitutions[:attachments] = resolved
  end

  #
  # Resolve a config value from the current item using FieldDefaults.calculate_default.
  # Supports {{curly}} substitutions, {{{raw}}} substitutions, conditional action hashes
  # (e.g. {this: {field: return_value}}), and literal values passed through unchanged.
  # @param [String | Hash | Object] value - value to resolve
  # @return [Object] resolved value
  def substitute_from_item(value)
    FieldDefaults.calculate_default(@item, value, allow_nil: true, ignore_missing: true)
  end

  #
  # The message importance for SMS messages, set by config[:importance]
  # Returns a string "transactional" (default) | "promotional"
  # May be retrieved dynamically from a conditional action calculation, or specified directly
  # @return [<Type>] <description>
  def importance
    @importance ||= calc_field_or_return(@config[:importance]) if @config[:importance]
  end

  # Rescues MessageNotification validation failures so one bad notify entry doesn't abort the rest.
  def create_message_notification_or_record_error
    create_message_notification
  rescue ActiveRecord::RecordInvalid => e
    msg = "Failed to create message notification: #{e.message}"
    Rails.logger.warn msg
    @item.save_trigger_results['notify_results'] << false
    @item.save_trigger_results['notify_errors'] << msg
    nil
  end

  def create_message_notification
    setup_data = {
      app_type: resolve_app_type,
      user: resolve_user,
      layout_template_name: @layout_template,
      content_template_name: content_template,
      content_template_text:,
      item_type: @item.class.name,
      item_id: @item.id,
      master_id: @item.master_id,
      message_type: @message_type,
      subject:,
      role_name: @role_name,
      extra_substitutions:
    }

    setup_data[:recipient_user_ids] = @receiving_user_ids if @receiving_user_ids
    setup_data[:recipient_sms_numbers] = @force_phones if @force_phones
    setup_data[:recipient_emails] = @force_emails if @force_emails
    setup_data[:recipient_data] = @force_recip_recs if @force_recip_recs
    setup_data[:importance] = importance if importance
    setup_data[:from_user_email] = from_user_email if from_user_email
    setup_data[:ignore_no_recipients] = @ignore_no_recipients if @ignore_no_recipients

    @message_notification = Messaging::MessageNotification.create! setup_data
  end

  def queue_job
    # Queue the job.
    self.job = HandleMessageNotificationJob
    # For testing and debugging mostly, allow this to run immediately inline
    self.job = job.set(run_when) if run_when && self.class.allow_future_processing
    # Pass in the MessageNotification as the main object
    # for_item is the ActivityLog instance that was triggered on save
    # Also pass the on_complete configuration to follow up after the main job processing completes
    job.perform_later(@message_notification, for_item: @item,
                                             on_complete_config: @on_complete,
                                             alt_batch_user: @alt_batch_user,
                                             ignore_no_recipients: @ignore_no_recipients)
  end

  def calc_field_or_return(cond)
    # Delegate to ConditionalActions which now handles:
    # - Hash conditions
    # - {{template}} substitutions via FieldDefaults
    # - Arrays (treated as array of literal values)
    # - Literal values
    FieldDefaults.calculate_default(item, cond, allow_nil: true, ignore_missing: true)
  end
end
