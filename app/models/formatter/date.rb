module Formatter
  module Date

      def self.format data, current_user: nil, iso: nil, utc: nil
        unless data.blank?

          if iso
            df = "%Y-%m-%d"
          elsif current_user
            df = current_user.user_preference.pattern_for_date_format
          else
            df = UserPreference.default_pattern_for_date_format
          end

          data = data.to_time.utc if utc

          res = data.strftime(df)

          return res
        end
        nil
      end

      def self.format_error_message data=nil
        "Check email address is a valid format."
      end


  end
end
