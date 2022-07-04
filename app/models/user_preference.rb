# frozen_string_literal: true

class UserPreference < UserBase
  # Essential method to indicate this does not have an association with a master record
  def self.no_master_association
    true
  end

  include UserHandler

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

  # Override to always allow access. The caller is responsible for allowing access.
  # Limited risk, even if misused.
  def allows_current_user_access_to?(_perform, _with_options = nil)
    true
  end

  def as_json(extras = {})
    extras[:methods] ||= []

    super
  end

  add_model_to_list # always at the end of model

  private

  def set_defaults
    self.date_format ||= UserPreference.default_date_format
    self.date_time_format ||= UserPreference.default_date_time_format
    self.time_format ||= UserPreference.default_time_format
    self.timezone ||= UserPreference.default_user_timezone
  end
end
