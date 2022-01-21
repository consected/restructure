# frozen_string_literal: true

class TimeZone < ActiveRecord::Base # With Rails 5.2 it should have been < ApplicationRecord.
  has_many :user_preferences

  validates :abbreviation, presence: true
  validates :name, presence: true
  validates :utc_offset, presence: true
end
