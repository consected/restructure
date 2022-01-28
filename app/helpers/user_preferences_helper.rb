# frozen_string_literal: true

module UserPreferencesHelper
  def timezone_options
    ActiveSupport::TimeZone.us_zones.map(&:name)
  end
end
