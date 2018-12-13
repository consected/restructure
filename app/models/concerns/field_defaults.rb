module FieldDefaults

  def self.calculate_default obj, default, type=nil
    default ||= ''

    res = default
    if default.is_a? String
      m = default.scan(/(-?+?\d+) (days|day|months|month|years|year)/)
      if m.first
        t = m.first.last
        res = DateTime.now + m.first.first.to_i.send(t)
      elsif default == 'now'
        res = DateTime.now
      elsif default == 'now()'
        res = DateTime.now
      elsif default == 'current_user'
        res = obj.current_user.id
      elsif default == 'current_user_email'
        res = obj.current_user.email
      end
    end

    if type == 'date'
      res = res.strftime('%Y-%m-%d') rescue nil
    end

    res
  end


end
