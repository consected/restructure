module Formatter
  module TimeWithZone
    def self.format(data, _options = nil, current_user: nil,
                    include_sec: nil,
                    time_only: nil, date_only: nil,
                    iso: nil, utc: nil, show_timezone: nil)
      return if data.blank?

      if current_user
        current_timezone = current_user.user_preference.timezone
        df = if include_sec
               current_user.user_preference.pattern_for_date_time_sec_format
             else
               current_user.user_preference.pattern_for_date_time_format
             end
      else
        df = if include_sec
               UserPreference.default_pattern_for_date_time_sec_format
             else
               UserPreference.default_pattern_for_date_time_format
             end
      end

      # If we are specifying a current_timezone and the data has a different UTC offset (in seconds)
      # then go ahead and parse the data with the specified timezone.
      # If the UTC offsets match then we'll just assume that they represent the same timezone
      # and return the formatted time without forcing a timezone onto it
      if current_timezone && data
        use_tz = current_timezone
        tz = ActiveSupport::TimeZone.new(use_tz)
        raise FphsException, "Unrecognized timezone '#{use_tz}'" unless tz
      end

      if use_tz && tz.utc_offset != data.utc_offset
        data = tz.parse(data.to_s)
        res = data.strftime(df).gsub('  ', ' ')
      else
        res = data.strftime(df).gsub(' ', ' ')
      end

      # Just want the time or date portion
      if time_only
        res = res.split(' ')[1..].join(' ')
      elsif date_only
        res = res.split(' ').first
      end

      res
    end

    def self.format_error_message(_data = nil)
      'Check time is a valid format.'
    end
  end
end
