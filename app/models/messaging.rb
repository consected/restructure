module Messaging

  def self.sms_aws_region=r
    @sms_aws_region = r
  end

  def self.sms_aws_region
    @sms_aws_region
  end

  def self.test_sms_number=n
    @test_sms_number = n
  end

  def self.test_sms_number
    @test_sms_number
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

  ActiveSupport.run_load_hooks(:messaging_setup, self)

end
