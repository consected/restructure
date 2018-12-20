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


  def self.send_now mn, logger: nil

    logger ||= Rails.logger
    logger.info "Sending sms for #{mn.id}"

    mn.recipient_sms_numbers.each do |sms_number|

      validate_sms_number sms_number

      client = Aws::SNS::Client.new(region: self.sms_aws_region)
      resp = client.publish(
        phone_number: sms_number,
        message: mn.generated_text,
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
    end


  end


  # Ensure that the configurations are loaded from initializers
  ActiveSupport.run_load_hooks(:messaging_notification_sms, self)

end
