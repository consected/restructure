# frozen_string_literal: true

# Configurations for AWS APIs.
# The actual configurations are defined in (config/initializers/app_settings_aws_api_setup.rb)
module AwsApiSetup
  def self.s3_aws_region=(r)
    @s3_aws_region = r
  end

  def self.s3_aws_region
    @s3_aws_region
  end

  def self.sms_aws_region=(r)
    @sms_aws_region = r
  end

  def self.sms_aws_region
    @sms_aws_region
  end

  def self.test_sms_number=(n)
    @test_sms_number = n
  end

  def self.test_sms_number
    @test_sms_number
  end

  def self.sender_id=(s)
    @sender_id = s
  end

  def self.sender_id
    @sender_id
  end

  def self.importance=(i)
    @importance = i
  end

  def self.importance
    @importance
  end

  def self.stub_responses
    Rails.env.test? && ENV['IGNORE_MFA'] == 'true'
  end

  ActiveSupport.run_load_hooks(:aws_api_setup, self)
end
