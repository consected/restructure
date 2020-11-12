class Messaging::PhoneValidation

  include AwsApi::SmsHandler

  attr_accessor :phone_number

  def self.validate_sms_number_format sms_number, no_exception: false
    valid = !!(sms_number && sms_number.match(/^\+[1-9][0-9]{1,14}$/))
    if sms_number[1] == '1'
      valid &&= !!(sms_number.match(/^\+1[0-9]{10}$/))
    end
    raise FphsException.new "Bad SMS number: #{sms_number}" unless no_exception || valid
    valid
  end

  def is_sms_number? sms_number, allow_voip: true

    valid = validate sms_number

    if valid
      mobile_types = MobileTypes.dup
      mobile_types += VoipTypes if allow_voip
      valid = valid[:phone_type].in? mobile_types
    end

    valid
  end

  def validate phone_number
    self.phone_number = phone_number
    valid = self.class.validate_sms_number_format phone_number, no_exception: true
    if valid
      res = validated_data
    else
      res = {phone_type: 'BAD FORMAT'}
    end
    res
  end

  def validated_data
    return @validated_data if @validated_data
    res = pp_phone_validate self.phone_number
    if res && res.number_validate_response
      h = res.number_validate_response.to_hash
    end

    @validated_data = h
  end

  def phone_number= pn
    @validated_data = nil
    @phone_number = pn
  end

end
