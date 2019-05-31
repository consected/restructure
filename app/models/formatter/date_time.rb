module Formatter
  module DateTime

      # @param data [Hash | Array] date and time as: {date: date, time: time} | [date, time]
      def self.format data, current_user: nil, iso: nil, utc: nil, show_timezone: nil
        unless data.blank?

          if data.is_a? Array
            w = {date: data[0], time: data[1]}
          elsif data.is_a? Hash
            w = data
          end

          if w
            data = "#{Formatter::Date.format w[:date], iso: iso, utc: utc} #{Formatter::Time.format w[:time], iso: iso, utc: utc}"
          end

          if data.is_a? String
            data = ::DateTime.parse(data)
          end

          if iso
            df = "%Y-%m-%d %H:%M:%S"
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

          res = data.strftime(df)
          res = nil if res.gsub(' ', '').blank?

          return res
        end
        nil
      end

      def self.format_error_message data=nil
        "Check email address is a valid format."
      end


  end
end
