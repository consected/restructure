# frozen_string_literal: true

module Formatter
  module Time
    IsoFormat = '%H:%M:%S'

    #
    # If a current_user is set and current_timezone == :user then:
    #   the current_user's timezone will be used to interpret the date / time to display.
    # Otherwise the timezone of the of the supplied data will be used.
    #
    # If a current_date is provided, the time will be evaluated for that date, which may cause it to appear differently
    # based on the current user's timezone (DST differences between timezones, etc)
    #
    # If utc is set, the date will be converted to UTC and the timezone will be displayed as UTC
    def self.format(data, _options = nil, current_user: nil,
                    include_sec: nil,
                    iso: nil, utc: nil, show_timezone: nil,
                    current_timezone: nil, current_date: nil)
      return nil if data.blank?

      current_timezone = current_user.user_preference.timezone if current_user && current_timezone&.to_sym == :user

      if current_timezone && current_date
        data = data.strftime(IsoFormat) if data.respond_to?(:strftime)
        use_tz = current_timezone
        tz = ActiveSupport::TimeZone.new(use_tz)
        raise FphsException, "Unrecognized timezone '#{use_tz}'" unless tz

        data = tz.parse("#{current_date} #{data}")
      end

      if utc
        data = data.to_time.utc
        show_timezone ||= 'UTC'
      end

      pattern = pattern_for(current_user, current_timezone, iso, include_sec, show_timezone)
      data.strftime(pattern).gsub('  ', ' ')
    end

    def self.pattern_for(current_user, current_timezone, iso, include_sec, show_timezone)
      pattern = if iso
                  IsoFormat
                elsif current_user
                  if include_sec
                    current_user.user_preference.pattern_for_time_sec_format
                  else
                    current_user.user_preference.pattern_for_time_format
                  end
                elsif include_sec
                  UserPreference.default_pattern_for_time_sec_format
                else
                  UserPreference.default_pattern_for_time_format
                end

      show_timezone = current_timezone if show_timezone == true
      pattern = "#{pattern} #{show_timezone}" if show_timezone
      pattern
    end

    def self.format_error_message(_data = nil)
      'Check email address is a valid format.'
    end
  end
end
