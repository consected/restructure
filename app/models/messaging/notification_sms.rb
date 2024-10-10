module Messaging
  class NotificationSms
    include AwsApi::SmsHandler

    BadFormatMsg = 'bad format phone number'.freeze

    #
    # Send a series of SMS messages to a list of recipients with the same message
    # @param mnobj [Messaging::MessageNotification] object describing the list of numbers and message
    # @param recipient_sms_numbers [Array | nil] optional list of SMS numbers to override message notification
    # @param generated_text [String | nil] optional message text to override message notification
    # @param ignore_no_recipients [true | nil] don't raise an error if no recipients are specified or found in the item
    def send_now(mnobj = nil, recipient_sms_numbers: nil, generated_text: nil, ignore_no_recipients: nil,
                 importance: nil, logger: nil)
      logger ||= Rails.logger

      importance ||= self.class.importance

      resp = []
      if recipient_sms_numbers
        logger.info 'Sending sms to a defined set of recipients'
      elsif mnobj
        logger.info "Sending sms for #{mnobj.id}"
      else
        raise FphsException, 'No message notification or recipient list set for SMS send'
      end

      recipient_sms_numbers ||= mnobj.recipient_sms_numbers
      generated_text ||= mnobj.generated_text

      unless recipient_sms_numbers&.present?
        return if ignore_no_recipients

        raise FphsException, 'No recipients to SMS'
      end

      recipient_sms_numbers.each do |sms_number|
        val = PhoneValidation.validate_sms_number_format sms_number, no_exception: true

        if val
          res = send_sms sms_number, generated_text, importance
          resp << { aws_sns_sms_message_id: res.message_id } if res
        else
          resp << { error: BadFormatMsg }
        end
      end

      resp.to_json
    end
  end
end
