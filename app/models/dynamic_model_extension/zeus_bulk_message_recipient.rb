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

      # The recipient update may run in a background job some time after
      # the bulk message was scheduled. If the user has switched to a
      # different app type since scheduling, their current app_type will
      # not grant edit access to this table and check_can_save will raise
      # FphsException. Temporarily switch the user's in-memory app_type
      # to the bulk message app for the duration of the update so the
      # access checks pass, then restore it afterwards. The user record
      # is not persisted with this change. See issue #1129.
      original_app_type = current_user&.app_type
      bulk_msg_app = Settings.bulk_msg_app
      current_user.app_type = bulk_msg_app if current_user && bulk_msg_app

      self.class.transaction do
        update!(current_user: current_user, response: response)
        # If there is a zeus_bulk_message_status, this is a retry. Mark the status as such so we can get a refreshed status
        zbms = zeus_bulk_message_status
        if zbms
          zbms.update!(status: 'retrying', current_user: current_user)
        end
      end
    ensure
      current_user.app_type = original_app_type if current_user
    end

  end
end
