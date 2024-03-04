# frozen_string_literal: true

module Formatter
  module DateTime
    IsoFormat = '%Y-%m-%d %H:%M:%S'
    # If a current_user is set and no data zone, the current_user's timezone will be used to interpret the date / time
    # @param [Hash | Array] data - date and time as: {date: date, time: time, zone: timezone} | [date, time, zone]
    # @param [nil] _options - unused
    # @param [User] current_user
    # @param [true] include_sec
    # @param [true] iso
    # @param [true] utc
    # @param [true] show_timezone
    # @param [true] keep_date - (optional) ensures the current date is kept, and just the time altered when forcing it to the new timezone.
    # @param [String] current_timezone
    # @return [String]
    def self.format(data, _options = nil,
                    current_user: nil,
                    include_sec: nil,
                    iso: nil,
                    utc: nil,
                    show_timezone: nil,
                    keep_date: nil,
                    current_timezone: nil)
      return nil if data.blank?

      if data.is_a? Array
        w = { date: data[0], time: data[1], zone: data[2] }
      elsif data.is_a? Hash
        w = data
      end

      if current_user&.user_preference && current_timezone&.to_sym == :user
        current_timezone = current_user.user_preference.timezone
      end

      if w
        curr_zone = w[:zone] || current_timezone
        if current_user&.user_preference && !curr_zone || curr_zone == :user
          curr_zone = current_user.user_preference.timezone
        end

        # Convert to iso format
        if keep_date
          dstr = Formatter::Date.format w[:date], iso: true
          data = "#{dstr} #{Formatter::Time.format w[:time], iso: true, utc: true,
                                                             current_timezone: curr_zone,
                                                             current_date: dstr, current_user: current_user,
                                                             include_sec: include_sec}"

        elsif curr_zone
          data = "#{w[:date]} #{w[:time]}"
          data = data.strftime(IsoFormat) if data.respond_to?(:strftime)
          use_tz = curr_zone
          tz = ActiveSupport::TimeZone.new(use_tz)
          raise FphsException, "Unrecognized timezone '#{use_tz}'" unless tz

          data = tz.parse(data)
        else
          data = "#{w[:date]} #{w[:time]}"
          data = ::DateTime.parse(data)
        end

        data = data.to_time.utc
        data = data.strftime("#{IsoFormat} UTC").gsub('  ', ' ')
      elsif current_user && current_timezone
        curr_zone = current_timezone
        curr_zone = current_user.user_preference.timezone if current_timezone == :user
        data = "#{data.utc.strftime(IsoFormat)} UTC" if data.respond_to?(:strftime)
        use_tz = curr_zone
        tz = ActiveSupport::TimeZone.new(use_tz)
        raise FphsException, "Unrecognized timezone '#{use_tz}'" unless tz

        data = tz.parse(data)
      end

      data = ::DateTime.parse(data) if data.is_a? String

      if utc
        data = data.to_time.utc
        show_timezone ||= 'UTC'
      end

      pattern = pattern_for(current_user, curr_zone, iso, include_sec, show_timezone)
      res = data.strftime(pattern)
      res = nil if res.gsub(' ', '').blank?

      res
    end

    def self.pattern_for(current_user, current_timezone, iso, include_sec, show_timezone)
      pattern = if iso
                  IsoFormat
                elsif current_user&.user_preference
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

      show_timezone = current_timezone if show_timezone == true
      pattern = "#{pattern} #{show_timezone}" if show_timezone
      pattern
    end

    def self.format_error_message(_data = nil)
      'Check email address is a valid format.'
    end
  end
end
