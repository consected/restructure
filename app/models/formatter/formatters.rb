# frozen_string_literal: true

module Formatter
  class Formatters
    def self.formatter_for(type)
      return unless type

      "Formatter::#{type.to_s.split('::').last.classify}".safe_constantize
    end

    def self.formatter_do(type, data, options = nil)
      options ||= {}
      ff = formatter_for(type)
      if ff
        ff.format(data, options)
      else
        data
      end
    end

    def self.formatter_error_message(type, data)
      ff = formatter_for(type)
      if ff
        ff.format_error_message(data)
      else
        'Check format.'
      end
    end

    def self.format_data_attribute(attr_conf, obj, ignore_missing: nil)
      if attr_conf.is_a? String
        if attr_conf.include?('{{')
          return Formatter::Substitution.substitute attr_conf, data: obj, tag_subs: nil, ignore_missing: ignore_missing
        end

        attr_conf = [attr_conf]
      end

      res = attr_conf.map do |i|
        got = false
        if obj.attributes.keys.include? i
          val = obj.attributes[i]
          got = true
        elsif obj.respond_to? i
          val = obj.send(i)
          got = true
        end

        res = if got
                item = Classification::SelectionOptionsHandler.label_for(obj, i, val)
                item || formatter_do(val.class, val, current_user: obj.current_user)
              else
                i
              end

        res
      end

      res.join(' ')
    end
  end
end
