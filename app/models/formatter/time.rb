module Formatter
  module Time

    def self.format data, current_user: nil, iso: nil, utc: nil, show_timezone: nil
      unless data.blank?
        if iso
          df = "%H:%M:%S"
        elsif current_user
          df = current_user.user_preference.pattern_for_date_time_format
        else
          df = UserPreference.default_pattern_for_date_time_format
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
