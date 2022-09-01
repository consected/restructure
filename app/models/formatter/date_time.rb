module Formatter
  module DateTime
    # If a current_user is set and no data zone, the current_user's timezone will be used to interpret the date / time
    # @param data [Hash | Array] date and time as: {date: date, time: time, zone: timezone} | [date, time, zone]
    def self.format(data, _options = nil,
                    current_user: nil,
                    include_sec: nil,
                    iso: nil, utc: nil, show_timezone: nil)
      unless data.blank?

        if data.is_a? Array
          w = { date: data[0], time: data[1], zone: data[2] }
        elsif data.is_a? Hash
          w = data
        end

        if w
          curr_zone = w[:zone]
          curr_zone = current_user.user_preference.timezone if current_user && !curr_zone || curr_zone == :user

          # Convert to iso format
          dstr = Formatter::Date.format w[:date], iso: true, utc: true
          data = "#{dstr} #{Formatter::Time.format w[:time], iso: true, utc: true,
                                                             current_timezone: curr_zone,
                                                             current_date: dstr, current_user: current_user,
                                                             include_sec: include_sec}"
        end

        data = ::DateTime.parse(data) if data.is_a? String #Ruby method

        df = if iso
               '%Y-%m-%d %H:%M:%S'
             elsif current_user
               if include_sec
                 current_user.user_preference.pattern_for_date_time_sec_format
               else
                 current_user.user_preference.pattern_for_date_time_format
               end
             elsif include_sec
               UserPreference.default_pattern_for_date_time_sec_format
             else
               UserPreference.default_pattern_for_date_time_format
             end

        if utc
          data = data.to_time.utc
          show_timezone ||= 'UTC'
        end

        show_timezone = curr_zone if show_timezone == true
        df = "#{df} #{show_timezone}" if show_timezone

        res = data.strftime(df)
        res = nil if res.gsub(' ', '').blank?

        return res
      end
      nil
    end

    def self.format_error_message(_data = nil)
      'Check email address is a valid format.'
    end
  end
end
