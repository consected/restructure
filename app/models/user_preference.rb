# frozen_string_literal: true

class UserPreference < UserBase
  # Essential method to indicate this does not have an association with a master record
  def self.no_master_association
    true
  end

  include UserHandler

  belongs_to :user, inverse_of: :user_preference

  after_initialize :set_defaults

  before_validation :map_patterns

  validates :date_format,
            presence: true

  validates :date_time_format,
            presence: true

  validates :pattern_for_date_format,
            presence: true

  validates :pattern_for_date_time_format,
            presence: true

  validates :pattern_for_time_format,
            presence: true

  validates :time_format,
            presence: true

  validates :timezone,
            presence: true

  def self.no_downcase_attributes
    %i[
      date_format time_format date_time_format timezone
      pattern_for_date_format pattern_for_time_format pattern_for_date_time_format
    ]
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
    UserPreferencesHelper::DateTimeFormats[UserPreference.default_date_time_format]
  end

  def self.default_pattern_for_time_format
    UserPreferencesHelper::TimeFormats[UserPreference.default_time_format]
  end

  # REMARK: to avoid confusion with ActiveRecord.default_timezone, added _user_ to its name.
  def self.default_user_timezone
    Settings::DefaultUserTimezone
  end

  add_model_to_list # always at the end of model

  private

  def set_defaults
    self.date_format ||= UserPreference.default_date_format
    self.date_time_format ||= UserPreference.default_date_time_format
    self.time_format ||= UserPreference.default_time_format
    self.timezone ||= UserPreference.default_user_timezone
    self.pattern_for_date_format ||= UserPreference.default_pattern_for_date_format
    self.pattern_for_date_time_format ||= UserPreference.default_pattern_for_date_time_format
    self.pattern_for_time_format ||= UserPreference.default_pattern_for_time_format
  end

  def map_patterns
    self.pattern_for_date_format = UserPreferencesHelper::DateFormats[self.date_format]
    self.pattern_for_date_time_format = UserPreferencesHelper::DateTimeFormats[self.date_time_format]
    self.pattern_for_time_format = UserPreferencesHelper::TimeFormats[self.time_format]
  end
end
