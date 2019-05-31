module Formatter
  module Time

    # If a current_user is set and no data zone, the current_user's timezone will be used to interpret the date / time
    def self.format data, current_user: nil, iso: nil, utc: nil, show_timezone: nil, current_timezone: nil, current_date: nil
      unless data.blank?
        if iso
          df = "%H:%M:%S"
        elsif current_user
          df = current_user.user_preference.pattern_for_date_time_format
        else
          df = UserPreference.default_pattern_for_date_time_format
        end

        if data.is_a?(String) && (current_timezone || current_user) && current_date
          use_tz = current_timezone || current_user.user_preference.timezone
          tz = ActiveSupport::TimeZone.new(use_tz)
          data = tz.parse("#{current_date} #{data}")
        end

        if utc
          data = data.to_time.utc
          show_timezone ||= :utc
        end

        df = "#{df} #{show_timezone.to_s.upcase}" if show_timezone

        res = data.strftime(df).gsub('  ', ' ')

        return res
      end
      nil
    end

    def self.format_error_message data=nil
      "Check email address is a valid format."
    end



  end
end
