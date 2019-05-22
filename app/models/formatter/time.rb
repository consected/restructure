module Formatter
  module Time

    def self.format data, current_user: nil
      unless data.blank?

        if current_user
          df = current_user.user_preference.pattern_for_date_time_format
        else
          df = UserPreference.default_pattern_for_date_time_format
        end
        data = data.strftime(df).gsub('  ', ' ')

        return data
      end
      nil
    end

    def self.format_error_message data=nil
      "Check email address is a valid format."
    end



  end
end
