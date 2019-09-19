module FieldDefaults

  def self.calculate_default obj, default, type=nil, from_when: nil
    default = '' if default.nil?

    res = default
    from_when ||= DateTime.now
    if default.is_a? String
      m = default.scan(/^(-?\+?\d+) (second|seconds|minute|minutes|hour|hours|days|day|months|month|years|year)/)
      if m.first
        t = m.first.last
        res = from_when + m.first.first.to_i.send(t)
      elsif default == 'id'
        res = obj&.id
      elsif default == 'now'
        res = from_when
      elsif default == 'now()'
        res = from_when
      elsif default == 'today()'
        res = from_when.iso8601.split('T').first
      elsif default == 'user_email'
        res = obj.user&.email
      elsif default == 'current_user'
        res = obj.current_user.id
      elsif default == 'current_user_email'
        res = obj.current_user.email
      elsif default == 'current_user_roles'
        res = obj.current_user.user_roles.active.pluck(:id)
      elsif default == 'current_user_role_names'
        res = obj.current_user.user_roles.active.pluck(:role_name)
      end
    elsif default.is_a? Hash
      ca = ConditionalActions.new default, obj
      res = ca.get_this_val
    end

    if type&.to_sym == :date
      res = res.strftime('%Y-%m-%d') rescue nil
    elsif type&.to_sym == :datetime_type && res.is_a?(String)
      res = DateTime.parse(res)
    end

    res
  end


end
