# frozen_string_literal: true

class UserPreference < UserBase
  # Essential method to indicate this does not have an association with a master record
  def self.no_master_association
    true
  end

  include UserHandler
  include UserPreferencesHelper

  belongs_to :user, inverse_of: :user_preference, autosave: true

  after_initialize :set_defaults

  validates :date_format,
            presence: true

  validates :date_time_format,
            presence: true

  validates :time_format,
            presence: true

  validates :timezone,
            presence: true

  def pattern_for_date_format
    UserPreferencesHelper::DateFormats[date_format] || UserPreference.default_pattern_for_date_format
  end

  def pattern_for_date_time_format
    UserPreferencesHelper::DateTimeFormats[date_time_format][:hours_minutes] ||
      UserPreference.default_pattern_for_date_time_sec_format
  end

  def pattern_for_time_format
    UserPreferencesHelper::TimeFormats[time_format][:hours_minutes] ||
      UserPreference.default_pattern_for_time_sec_format
  end

  def pattern_for_date_time_sec_format
    UserPreferencesHelper::DateTimeFormats[date_time_format][:with_secs] ||
      UserPreference.default_pattern_for_date_time_format
  end

  def pattern_for_time_sec_format
    UserPreferencesHelper::TimeFormats[time_format][:with_secs] ||
      UserPreference.default_pattern_for_time_format
  end

  def timezone_iana
    #map to iana value tz
    ActiveSupport::TimeZone::MAPPING[self.timezone]
  end

  # Override to always allow access. The caller is responsible for allowing access.
  # Limited risk, even if misused.
  def allows_current_user_access_to?(_perform, _with_options = nil)
    true
  end

  def as_json(extras = {})
    extras[:methods] ||= []
    extras[:methods] << :timezone_iana
    # Call #serializable_hash rather than super, since we don't want to return
    # all the unnecessary attributes / methods provided by GeneralDataConcerns#as_json
    serializable_hash(extras)
  end

  def self.no_downcase_attributes
    %i[date_format time_format date_time_format timezone]
  end

  def self.default_date_format
    Settings::DefaultDateFormat
  end

  def self.default_date_time_format
    Settings::DefaultDateTimeFormat
  end

  def self.default_time_format
    Settings::DefaultTimeFormat
  end

  def self.default_pattern_for_date_format
    UserPreferencesHelper::DateFormats[UserPreference.default_date_format]
  end

  def self.default_pattern_for_date_time_format
    UserPreferencesHelper::DateTimeFormats[UserPreference.default_date_time_format][:hours_minutes]
  end

  def self.default_pattern_for_date_time_sec_format
    UserPreferencesHelper::DateTimeFormats[UserPreference.default_date_time_format][:with_secs]
  end

  def self.default_pattern_for_time_format
    UserPreferencesHelper::TimeFormats[UserPreference.default_time_format][:hours_minutes]
  end

  def self.default_pattern_for_time_sec_format
    UserPreferencesHelper::TimeFormats[UserPreference.default_time_format][:with_secs]
  end

  # REMARK: to avoid confusion with ActiveRecord.default_timezone, added _user_ to its name.
  def self.default_user_timezone
    Settings::DefaultUserTimezone
  end

  # Ensure we don't attempt to look for flags against a user preference instance
  def self.uses_item_flags?(_user)
    false
  end

  # Make sure that as_json doesn't recurse
  undef user_preference

  add_model_to_list # always at the end of model

  private

  def localized
    return @localized if @localized

    @localized = {}
    client_localized = user.client_localized
    return @localized unless client_localized.present?

    @localized = JSON.parse(client_localized)
  rescue StandardError
    @localized
  end

  def localized_date_formatter
    formatter = localized['date_formatter']&.downcase

    return UserPreference.default_date_format unless date_format_options.include?(formatter)

    formatter
  end

  def localized_time_formatter
    formatter = localized['time_formatter']

    return UserPreference.default_time_format unless formatter.present?
    return 'hh:mm am/pm' if formatter == 'h:mm A'

    '24h:mm'
  end

  def localized_date_time_formatter
    "#{localized_date_formatter} #{localized_time_formatter}"
  end

  def localized_timezone
    ActiveSupport::TimeZone::MAPPING.key(localized['timezone']) || UserPreference.default_user_timezone
  end

  def set_defaults
    self.date_format ||= localized_date_formatter
    self.date_time_format ||= localized_date_time_formatter
    self.time_format ||= localized_time_formatter
    self.timezone ||= localized_timezone
  end
end
