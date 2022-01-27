# frozen_string_literal: true

class UserPreference < UserBase
  # Essential method to indicate this does not have an association with a master record
  def self.no_master_association
    true
  end

  include UserHandler

  belongs_to :user, inverse_of: :user_preference

  after_initialize :set_defaults

  validates :date_format,
            presence: true

  validates :pattern_for_date_format,
            presence: true

  validates :pattern_for_date_time_format,
            presence: true

  validates :pattern_for_time_format,
            presence: true

  def self.base_route_name
    'user_preference'
  end

  def self.base_route_segments
    'user_preference'
  end

  # put  validations here
  def self.default_pattern_for_date_format
    '%m/%d/%Y'
  end

  def self.default_pattern_for_date_time_format
    '%m/%d/%Y %l:%M%p'
  end

  def self.default_pattern_for_time_format
    '%l:%M%p'
  end

  add_model_to_list # always at the end of model

  private

  def set_defaults
    self.date_format ||= UserPreference.default_pattern_for_date_format
    self.pattern_for_date_format ||= UserPreference.default_pattern_for_date_format
    self.pattern_for_date_time_format ||= UserPreference.default_pattern_for_date_time_format
    self.pattern_for_time_format ||= UserPreference.default_pattern_for_time_format
  end
end
