class Messaging::NotificationSms

  def self.sms_aws_region=r
    @sms_aws_region = r
  end

  def self.sms_aws_region
    @sms_aws_region
  end

  def self.sender_id=s
    @sender_id = s
  end

  def self.sender_id
    @sender_id
  end

  def self.importance= i
    @importance = i
  end

  def self.importance
    @importance
  end

  def self.validate_sms_number sms_number, no_exception: false
    valid = !!(sms_number && sms_number.match(/^\+[1-9][0-9]{1,14}$/))
    raise FphsException.new "Bad SMS number: #{sms_number}" unless no_exception || valid

    valid
  end

  # Send a series of SMS messages to a list of recipients with the same message
  # @param mn [Messaging::MessageNotification] object describing the list of numbers and message
  # @param recipient_sms_numbers [Array | nil] optional list of SMS numbers to override message notification
  # @param generated_text [String | nil] optional message text to override message notification
  def self.send_now mn=nil, recipient_sms_numbers: nil, generated_text: nil, logger: nil
    logger ||= Rails.logger

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

      validate_sms_number sms_number

      sms_number = '+16177942330' unless Rails.env.production?

      client = Aws::SNS::Client.new(region: self.sms_aws_region)
      res = client.publish(
        phone_number: sms_number,
        message: generated_text,
        message_attributes: {
          "AWS.SNS.SMS.SenderID" => {
            data_type: "String",
            string_value: self.sender_id
          },
          "AWS.SNS.SMS.SMSType" => {
            data_type: "String",
            string_value: self.importance
          }
        }
      )
      resp << {aws_sns_sms_message_id: res.message_id} if res
    end

    resp.to_json

  end


  # Ensure that the configurations are loaded from initializers
  ActiveSupport.run_load_hooks(:messaging_notification_sms, self)

end
