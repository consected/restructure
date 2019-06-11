module Formatter
  module TimeWithZone

    def self.format data, options=nil, current_user: nil, iso: nil, utc: nil, show_timezone: nil
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
          raise FphsException.new "Unrecognized timezone '#{use_tz}'" unless tz
          data = tz.parse(data.to_s)
          res = data.strftime(df).gsub('  ', ' ')
        else
          res = data.strftime(df).gsub(' ', ' ')
        end

        return res
      end
      nil
    end

    def self.format_error_message data=nil
      "Check email address is a valid format."
    end



  end
end
