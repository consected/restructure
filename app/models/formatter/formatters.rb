# frozen_string_literal: true

module Formatter
  module Formatters
    extend ActiveSupport::Concern

    class_methods do
      def formatter_for(type)
        return unless type

        "Formatter::#{type.to_s.split('::').last.classify}".safe_constantize
      end

      def formatter_do(type, data, options = nil)
        options ||= {}
        ff = formatter_for(type)
        if ff
          ff.format(data, options)
        else
          data
        end
      end

      def formatter_error_message(type, data)
        ff = formatter_for(type)
        if ff
          ff.format_error_message(data)
        else
          'Check format.'
        end
      end

      def format_data_attribute(attr_conf, obj)
        attr_conf = [attr_conf] if attr_conf.is_a? String

        res = attr_conf.map do |i|
          res = if obj.attribute_names.include?(i)
                  val = obj.attributes[i]

                  fs = Classification::GeneralSelection.field_selections_hashes
                  rn = "#{obj.resource_name}_#{i}".to_sym
                  item = fs[rn] && fs[rn][val] && fs[rn][val][:name]
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
end
