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

    @model_defs = config.deep_dup
    @model_defs = [@model_defs] unless @model_defs.is_a? Array
  end

  #
  # Iterate through each configuration to handle notifications if
  # defined conditions are met.
  # Setup the notification from the configuration and schedule it to run
  # in the background, either immediately or in the future
  def perform
    @model_defs.each do |config|
      init_attribs config
      next unless run_this?

      if @role || @users
        setup_role_and_users
      elsif @phones
        setup_phones
      elsif @phone_records
        setup_recipient_data
      elsif @emails
        setup_emails
      else
        raise FphsException, 'role, users or phones must be specified in save_trigger: notify: role: ...'
      end

      if !@receiving_user_ids&.present? && !@force_phones && !@force_emails && !@force_recip_recs
        Rails.logger.warn "No recipients based on role: #{@role}, users or specified phones/emails in #{self.class.name}"
        next
      end

      if filter_notifications && @receiving_user_ids.empty?
        Rails.logger.info 'No recipients after filtering'
        next
      end

      create_message_notification
      res = queue_job

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
    @on_complete = config[:on_complete]
    @from_user_email = config[:from_user_email]
    @ignore_no_recipients = config[:ignore_no_recipients]

    @message_type = config[:type]
    @run_if = config[:if]
    @alt_batch_user = DynamicModel.user_for_conf_snippet(config)

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

  #
  # Set up the roles and users to get a list of receiving user IDs
  def setup_role_and_users
    # Allow both role and users to be specified
    @receiving_user_ids = []

    if @role

      @role = @role.reject(&:blank?) if @role.is_a? Array
      @role_name = calc_field_or_return(@role)
      @role_name = @role_name.reject(&:blank?) if @role_name.is_a? Array

      @receiving_user_ids += Admin::UserRole.active_user_ids role_name: @role_name, app_type: @user.app_type
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

  def setup_phones
    @force_phones = calc_field_or_return(@phones)

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

  def setup_emails
    @force_emails = calc_field_or_return(@emails)
    @force_emails = [@force_emails] if @force_emails.is_a? String
    @force_emails
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
  # If a hash is specified then the text will be retreived using a conditional action
  # @return [String | nil]
  def content_template_text
    @content_template_text ||= calc_field_or_return(@config[:content_template_text])
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
  # @return [Hash | nil]
  def extra_substitutions
    return @extra_substitutions if @extra_substitutions

    @extra_substitutions = config[:extra_substitutions]

    @extra_substitutions&.each do |k, v|
      @extra_substitutions[k] = Formatter::Substitution.substitute(v, data: @item, tag_subs: nil, ignore_missing: true)
    end
  end

  #
  # The message importance for SMS messages, set by config[:importance]
  # Returns a string "transactional" (default) | "promotional"
  # May be retrieved dynamically from a conditional action calculation, or specified directly
  # @return [<Type>] <description>
  def importance
    @importance ||= calc_field_or_return(@config[:importance]) if @config[:importance]
  end

  def create_message_notification
    setup_data = {
      app_type: @user.app_type,
      user: @user,
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
    ConditionalActions.calc_field_or_return cond, item
  end
end
