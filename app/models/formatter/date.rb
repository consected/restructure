# frozen_string_literal: true

module Formatter
  module Date
    #
    # @param [Date|DateTime|Time] data - the date to be used, preferably as a Date or as a Time in the server timezone
    # @param [nil] _options - unused
    # @param [true] iso - (optional) request a YY-MM-DD string result.
    # @param [User] current_user - (optional) if the *iso* is not specified, current user
    #                                         date format preference will be used.
    #                              If iso is nil and current_user is nil then we just use
    #                              the server default date pattern
    # @param [true] utc - (optional) force a Time or Date to UTC. When specifying a Date on a server
    #                     with 'TZ' environment
    #                     variable set to UTC this will have not have a real effect. In other scenarios
    #                     the date may return
    #                     a different day when converted back to a string, due to timezone differences. When a Time is
    #                     specified the result will depend on the timezone specified in the Time instance.
    # @return [String] - result formatted based on requested date format
    def self.format(data, _options = nil,
                    current_user: nil,
                    iso: nil,
                    utc: nil)
      return if data.blank?

      df = if iso
             '%Y-%m-%d'
           elsif current_user&.user_preference
             current_user.user_preference.pattern_for_date_format
           else
             UserPreference.default_pattern_for_date_format
           end

      data = data.to_time.utc if utc

      data.strftime(df)
    end

    def self.format_error_message(_data = nil)
      'Check email address is a valid format.'
    end
  end
end
