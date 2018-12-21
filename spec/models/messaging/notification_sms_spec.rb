# Test the underlying SMS sending capability
# Actual notify functionality for any method of delivery is tested by SaveTriggers::NotifySpec
require 'rails_helper'

RSpec.describe Messaging::NotificationSms, type: :model do

  include ModelSupport
  include ActivityLogSupport

  before :all do
    create_admin
  end

  before :each do

    @message_notification = Messaging::MessageNotification.new
    @message_notification.generated_text = 'This is a test message to send via the SMS service'

  end

  it "validates an sms number" do
    @message_notification.recipient_sms_numbers = ['+12025550147']
    expect {
      Messaging::NotificationSms.validate_sms_number('87236476234')
    }.to raise_error FphsException

    expect {
      Messaging::NotificationSms.validate_sms_number('+87236476234')
    }.not_to raise_error

    res = Messaging::NotificationSms.validate_sms_number('+87236476234', no_exception: true)
    expect(res).to be true

    res = Messaging::NotificationSms.validate_sms_number('87236476234', no_exception: true)
    expect(res).to be false

    res = Messaging::NotificationSms.validate_sms_number('+872.364.76234', no_exception: true)
    expect(res).to be false

  end



  it "gets user SMS numbers from a query of users" do

    u1, _ = create_user
    u2, _ = create_user
    u3, _ = create_user

    @message_notification.recipient_user_ids = [u1.id, u2.id, u3.id]

    nums = @message_notification.recipient_sms_numbers

    expect(nums.length).to eq 0

    Users::ContactInfo.create! sms_number: '+1-202-555-0147', user: u2, current_admin: @admin

    expect {
      Users::ContactInfo.create! sms_number: '12025550147', user: u1, current_admin: @admin
    }.to raise_error ActiveRecord::RecordInvalid

    Users::ContactInfo.create! sms_number: '+12025550147', user: u1, current_admin: @admin

    nums = @message_notification.recipient_sms_numbers
    expect(nums.length).to eq 1
    expect(nums[0]).to eq '+12025550147'

    Users::ContactInfo.create! sms_number: '+1-202-555-0156', user: u3, current_admin: @admin
    nums = @message_notification.recipient_sms_numbers
    expect(nums.length).to eq 2
    expect(nums).to include '+12025550147'
    expect(nums).to include '+12025550156'

    Messaging::NotificationSms.send_now @message_notification
  end

  it "sends an sms" do
    sms = Messaging::NotificationSms.send_now @message_notification
  end

end
