module Formatter
  module Time
    IsoFormat = '%H:%M:%S'.freeze

    # If a current_user is set and no data zone, the current_user's timezone will be used to interpret the date / time
    def self.format(data, _options = nil, current_user: nil,
                    include_sec: nil,
                    iso: nil, utc: nil, show_timezone: nil,
                    current_timezone: nil, current_date: nil)
      unless data.blank?

        df = if iso
               IsoFormat
             elsif current_user
               current_timezone = current_user.user_preference.timezone if current_timezone&.to_sym == :user
               df = if include_sec
                      current_user.user_preference.pattern_for_time_sec_format
                    else
                      current_user.user_preference.pattern_for_time_format
                    end
             else
               df = if include_sec
                      UserPreference.default_pattern_for_time_sec_format
                    else
                      UserPreference.default_pattern_for_time_format
                    end
             end

        if current_timezone && current_date
          data = data.strftime(IsoFormat) if data.respond_to?(:strftime)
          use_tz = current_timezone
          tz = ActiveSupport::TimeZone.new(use_tz)
          raise FphsException, "Unrecognized timezone '#{use_tz}'" unless tz

          data = tz.parse("#{current_date} #{data}")
        end

        if utc
          data = data.to_time.utc
          show_timezone ||= :utc
        end

        show_timezone = current_timezone if show_timezone == true

        df = "#{df} #{show_timezone.to_s.upcase}" if show_timezone

        res = data.strftime(df).gsub('  ', ' ')

        return res
      end
      nil
    end

    def self.format_error_message(_data = nil)
      'Check email address is a valid format.'
    end
  end
end
