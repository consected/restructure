module DynamicModelExtension
  module ZeusBulkMessageRecipient

    extend ActiveSupport::Concern

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

    def received?
      zeus_bulk_message_status&.status
    end

    # @return [Boolean|Nil] returns :
    # => nil if not yet sent
    # => false if send was successful or something failed but does not allow a retry
    # => true if we failed for a retriable reason
    def can_retry?
      return unless self.response
      zeus_bulk_message_status&.can_retry?
    end

    def set_response current_user, response

      self.class.transaction do
        update!(current_user: current_user, response: response)
        # If there is a zeus_bulk_message_status, this is a retry. Mark the status as such so we can get a refreshed status
        zbms = zeus_bulk_message_status
        if zbms
          zbms.update!(status: 'retrying', current_user: current_user)
        end
      end

    end

  end
end
