module DynamicModelExtension
  module ZeusBulkMessageRecipient

    extend ActiveSupport::Concern

    ValidStatuses = [:success, :failure]

    included do
      has_one :zeus_bulk_message_status
    end

    class_methods do

      def extension_setup
      end

    end

    def send_status

      return "not sent" unless self.response

      got_message_id = self.response.match(/.+"aws_sns_sms_message_id".+/)
      got_error = self.response.scan(/"error": "([^"]+)"+/)&.first&.first

      if got_message_id
        strec = zeus_bulk_message_status
        strec&.status || 'sent'
      elsif got_error
        return got_error
      else
        "sent"
      end

    end



  end
end
