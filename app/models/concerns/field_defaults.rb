# frozen_string_literal: true

module FieldDefaults
  #
  # Calculate the value for field defaults and simple
  # data attribute substitutions.
  # Strings with {{tags}} are substituted using the Formatter::Substitution class
  # If the value is a Hash, use ConditionalActions#get_this_value
  # @param [UserBase] obj - the instance to use data from
  # @param [String|Number|Hash|nil] value - the value to perform substitutions on
  # @param [Symbol|nil] type - optionally specify a specific date or datetime type
  # @param [DateTime] from_when - a DateTime to use instead of now
  # @param [Boolean] allow_nil - by default, return empty string instead of nil. Set true to allow nils
  # @return [String|Number|nil] the result after substitutions
  def self.calculate_value(obj, value, type = nil, from_when: nil, allow_nil: false)
    value = '' if value.nil? && !allow_nil

    res = value
    from_when ||= DateTime.now
    if value.is_a? String
      m = value.scan(/^(-?\+?\d+) (second|seconds|minute|minutes|hour|hours|days|day|months|month|years|year)/)
      if m.first
        t = m.first.last
        res = from_when + m.first.first.to_i.send(t)
      elsif value == 'id'
        res = obj&.id
      elsif value == 'now'
        res = from_when
      elsif value == 'now()'
        res = from_when
      elsif value == 'today()'
        res = from_when.iso8601.split('T').first
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
      elsif value.include? '{{'
        res = Formatter::Substitution.substitute(value, data: obj, tag_subs: nil)
      end
    elsif value.is_a? Hash
      ca = ConditionalActions.new value, obj
      res = ca.get_this_val
    end

    if type&.to_sym == :date
      res = begin
              res.strftime('%Y-%m-%d')
            rescue StandardError
              nil
            end
    elsif type&.to_sym == :datetime_type && res.is_a?(String)
      res = DateTime.parse(res)
    end

    res
  end
end
