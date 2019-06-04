module Formatter
  module TimeWithZone

    def self.format data, options=nil, current_user: nil, iso: nil, utc: nil, show_timezone: nil
      unless data.blank?

        if current_user
          df = current_user.user_preference.pattern_for_date_time_format
        else
          df = UserPreference.default_pattern_for_date_time_format
        end
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
