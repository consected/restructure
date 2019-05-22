module Formatter
  module Formatters

    extend ActiveSupport::Concern

    class_methods do

      def formatter_for type
        return unless type
        "Formatter::#{type.to_s.split('::').last.classify}".safe_constantize
      end

      def formatter_do type, data, options=nil
        ff = formatter_for(type)
        if ff
          ff.format(data, options)
        else
          data
        end
      end

      def formatter_error_message type, data
        ff = formatter_for(type)
        if ff
          ff.format_error_message(data)
        else
          'Check format.'
        end
      end

    end

  end
end
