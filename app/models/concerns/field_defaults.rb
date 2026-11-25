# frozen_string_literal: true

module FieldDefaults
  #
  # Calculate the value for field defaults and simple
  # data attribute substitutions.
  # Strings with {{tags}} are substituted using the Formatter::Substitution class
  # If the value is a Hash with a single key 'object', return the inner value directly
  # to allow storing objects to JSONB fields. Otherwise, use ConditionalActions#get_this_val
  # @param [UserBase] obj - the instance to use data from
  # @param [String|Number|Hash|nil] value - the value to perform substitutions on
  # @param [Symbol|nil] type - optionally specify a specific date or datetime type
  # @param [DateTime] from_when - a DateTime to use instead of now
  # @param [Boolean] allow_nil - by default, return empty string instead of nil. Set true to allow nils
  # @return [String|Number|Hash|nil] the result after substitutions
  def self.calculate_default(obj, value, type = nil, from_when: nil, allow_nil: false, ignore_missing: false)
    value = '' if value.nil? && !allow_nil

    res = value
    from_when ||= DateTime.now
    if value.is_a? String
      dur = duration(value)
      if dur
        res = from_when + dur
      elsif value == 'id'
        res = obj&.id
      elsif value == 'now'
        res = from_when
      elsif value == 'now()'
        res = from_when
      elsif value == 'today()'
        res = from_when.iso8601.split('T').first
      elsif value == 'time()'
        res = from_when.iso8601.split('T').last.split('+').first
      elsif value == 'current_user_time'
        res = Formatter::TagFormatter.new.time_ignore_zone(nil, from_when)
      elsif value == 'user_email'
        res = obj.user&.email
      elsif value == 'current_user'
        res = obj.current_user.id
      elsif value == 'current_user_email'
        res = obj.current_user.email
      elsif value == 'current_user_roles'
        res = obj.current_user.user_roles.active.pluck(:id)
      elsif value == 'current_user_role_names'
        res = obj.current_user.user_roles.active.pluck(:role_name)
      elsif value.include? '{{{'
        res = Formatter::Substitution.substitute_plain(value, data: obj)
      elsif value.include? '{{'
        res = Formatter::Substitution.substitute(value, data: obj, tag_subs: nil, ignore_missing:)
      end
    elsif value.is_a? Hash
      if value.length == 1 && (value.key?(:object) || value.key?('object'))
        # A Hash with a single 'object' key passes the inner value through directly,
        # allowing JSONB fields to store arbitrary objects (issue #943)
        # Recursively substitute string values within the inner object (issue #956)
        inner = value[:object] || value['object']
        res = substitute_value_recurse(obj, inner, allow_nil:, ignore_missing:)
      else
        ca = ConditionalActions.new value, obj
        res = ca.get_this_val
      end
    end

    parse_date_and_time(res, type)
  end

  #
  # Recursively substitute string values within a nested structure of
  # hashes and arrays, applying calculate_default to each string value.
  # Non-string, non-hash, non-array values are returned as-is.
  # @param [UserBase] obj - the instance to use data from
  # @param [Object] value - the value to recursively substitute
  # @param [Boolean] allow_nil - pass through to calculate_default
  # @param [Boolean] ignore_missing - pass through to calculate_default
  # @return [Object] the value with all string values substituted
  def self.substitute_value_recurse(obj, value, allow_nil: false, ignore_missing: false)
    case value
    when Hash
      value.transform_values { |v| substitute_value_recurse(obj, v, allow_nil:, ignore_missing:) }
    when Array
      value.map { |v| substitute_value_recurse(obj, v, allow_nil:, ignore_missing:) }
    when String
      calculate_default(obj, value, allow_nil:, ignore_missing:)
    else
      value
    end
  end

  #
  # Parse a schedule time such as '6:00pm', 'monday 8:00am' or '2026-05-01 02:00' in the current time zone
  # @param [String | Time | DateTime | ActiveSupport::TimeWithZone] value
  # @return [nil | ActiveSupport::TimeWithZone | Time] nil if the value can not be parsed to a time
  def self.parse_run_at(value)
    return value if value.respond_to?(:acts_like_time?) && value.acts_like_time?
    return unless value.is_a?(String)

    Time.zone.parse(value)
  rescue ArgumentError
    nil
  end

  #
  # Check that a run_at value is a time, or a list of times, that can be scheduled
  # @param [String | Time | Array] value
  # @param [Boolean] single - true if a list of times is not allowed
  # @return [Boolean]
  def self.valid_run_at?(value, single: false)
    return false if value.blank? || (single && value.is_a?(Array))

    Array.wrap(value).all? { |v| parse_run_at(v) }
  end

  #
  # A recurring schedule interval: a positive duration, so that a schedule always advances.
  # @param [String | nil] value
  # @return [nil | duration]
  def self.recurring_interval(value)
    return unless value.is_a?(String)

    interval = duration(value)
    interval if interval&.positive?
  end

  #
  # Convert something like "15 minutes" or "-1 day" to a usable duration
  # @param [String] value
  # @return [nil | duration]
  def self.duration(value)
    m = value.scan(
      /^(-?\+?\d+)\ (second|seconds|minute|minutes|hour|hours|weeks|week|days|day|months|month|years|year)$/x
    )
    return unless m.first

    t = m.first.last
    m.first.first.to_i.send(t)
  end

  #
  # Parse a string to a Date or DateTime
  # If a type is not matched, return the input value
  # @param [String] value
  # @param [Symbol | String] type - :date | :datetime_type | anything else does nothing
  # @return [Date | DateTime | Object] parsed date or date time or the input value
  def self.parse_date_and_time(value, type)
    if type&.to_sym == :date
      begin
        value.strftime('%Y-%m-%d')
      rescue StandardError
        nil
      end
    elsif type&.to_sym == :datetime_type && value.is_a?(String)
      DateTime.parse(value)
    else
      value
    end
  end
end
