# frozen_string_literal: true

# Set up AWS API default configurations
ActiveSupport.on_load(:aws_api_setup) do
  self.default_aws_region = ENV['AWS_REGION'] || 'us-east-1'
  self.sms_aws_region = ENV['SMS_AWS_REGION'] || default_aws_region
  self.s3_aws_region =  ENV['S3_AWS_REGION'] || default_aws_region

  if Rails.env.production?
    self.sender_id = ENV['SMS_SENDER_ID']
    self.importance = (ENV['SMS_IMPORTANCE'] == 'low' ? 'Promotional' : 'Transactional')
  else
    self.sender_id = 'smstest'
    self.importance = 'Transactional'
  end

  # Select a number from https://fakenumber.org/us/boston
  self.test_sms_number = '+16175550118'
end
