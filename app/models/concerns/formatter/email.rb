module Formatter
  module Email
    extend ActiveSupport::Concern

    class_methods do

      # Format a phone number to US format: "(aaa)bbb-cccc[ optional-freetext]"
      def format_email data
        unless data.blank?
          return data
        end
        nil
      end

      def format_error_message data=nil
        "Check email address is a valid format."
      end

    end


  end
end
