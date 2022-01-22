# frozen_string_literal: true

class UserPreference < ActiveRecord::Base
  belongs_to :user

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

  # Essential method to indicate this does not have an association with a master record
  def self.no_master_association
    true
  end
end
