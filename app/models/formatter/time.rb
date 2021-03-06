module Formatter
  module Time
    IsoFormat = '%H:%M:%S'.freeze

    # If a current_user is set and no data zone, the current_user's timezone will be used to interpret the date / time
    def self.format(data, _options = nil, current_user: nil, iso: nil, utc: nil, show_timezone: nil, current_timezone: nil, current_date: nil)
      unless data.blank?

        current_timezone = current_user.user_preference.timezone if current_timezone&.to_sym == :user && current_user

        df = if iso
               IsoFormat
             elsif current_user
               current_user.user_preference.pattern_for_date_time_format
             else
               UserPreference.default_pattern_for_date_time_format
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
