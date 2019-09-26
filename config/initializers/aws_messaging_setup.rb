ActiveSupport.on_load(:messaging_setup) do
  self.sms_aws_region = ENV['SMS_AWS_REGION'] || 'us-east-1'
  if Rails.env.production?
    self.sender_id = ENV['SMS_SENDER_ID']
    self.importance = (ENV['SMS_IMPORTANCE'] == 'low' ? 'Promotional' : 'Transactional')
  else
    self.sender_id = 'smstest'
    self.importance = 'Transactional'
  end

  self.test_sms_number = '+16177942330'

end
