module Formatter
  module TimeWithZone
    def self.format(data, _options = nil, current_user: nil, iso: nil, utc: nil, show_timezone: nil, time_only: nil, date_only: nil)
      unless data.blank?

        if current_user
          current_timezone = current_user.user_preference.timezone
          df = current_user.user_preference.pattern_for_date_time_format
        else
          df = UserPreference.default_pattern_for_date_time_format
        end

        if current_timezone && data

          use_tz = current_timezone
          tz = ActiveSupport::TimeZone.new(use_tz)
          raise FphsException, "Unrecognized timezone '#{use_tz}'" unless tz

          data = tz.parse(data.to_s)
          res = data.strftime(df).gsub('  ', ' ')
        else
          res = data.strftime(df).gsub(' ', ' ')
        end

        # Just want the time or date portion
        if time_only
          res = res.split(' ').last
        elsif date_only
          res = res.split(' ').first
        end

        return res
      end
      nil
    end

    def self.format_error_message(_data = nil)
      'Check email address is a valid format.'
    end
  end
end
