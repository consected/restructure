module Messaging
  class NotificationSms

    include AwsApi::SmsHandler

    BadFormatMsg = 'bad format phone number'.freeze

    # Send a series of SMS messages to a list of recipients with the same message
    # @param mn [Messaging::MessageNotification] object describing the list of numbers and message
    # @param recipient_sms_numbers [Array | nil] optional list of SMS numbers to override message notification
    # @param generated_text [String | nil] optional message text to override message notification
    def send_now mn=nil, recipient_sms_numbers: nil, generated_text: nil, importance: nil, logger: nil
      logger ||= Rails.logger

      importance ||= self.class.importance

      resp = []
      if recipient_sms_numbers
        logger.info "Sending sms to a defined set of recipients"
      elsif mn
        logger.info "Sending sms for #{mn.id}"
      else
        raise FphsException.new "No message notification or recipient list set for SMS send"
      end

      recipient_sms_numbers ||= mn.recipient_sms_numbers
      generated_text ||= mn.generated_text

      raise FphsException.new "No recipients to SMS" unless recipient_sms_numbers

      recipient_sms_numbers.each do |sms_number|

        val = PhoneValidation.validate_sms_number_format sms_number, no_exception: true

        if val
          res = send_sms sms_number, generated_text, importance
          resp << {aws_sns_sms_message_id: res.message_id} if res
        else
          resp << {error: BadFormatMsg}
        end

      end

      resp.to_json

    end



  end
end
