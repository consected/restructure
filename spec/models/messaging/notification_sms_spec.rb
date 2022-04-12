# Test the underlying SMS sending capability
# Actual notify functionality for any method of delivery is tested by SaveTriggers::NotifySpec
require 'rails_helper'

RSpec.describe Messaging::NotificationSms, type: :model do
  include ModelSupport
  include ActivityLogSupport
  include AwsApiStubs

  before :example do
    create_admin

    @message_notification = Messaging::MessageNotification.new message_type: :sms
    @message_notification.generated_text = 'This is a test message to send via the SMS service'

    setup_stub(:sns_send_sms)
  end

  it 'validates an sms number' do
    @message_notification.recipient_sms_numbers = ['+12025550147']
    expect do
      Messaging::PhoneValidation.validate_sms_number_format('87236476234')
    end.to raise_error FphsException

    expect do
      Messaging::PhoneValidation.validate_sms_number_format('+87236476234')
    end.not_to raise_error

    res = Messaging::PhoneValidation.validate_sms_number_format('+87236476234', no_exception: true)
    expect(res).to be true

    res = Messaging::PhoneValidation.validate_sms_number_format('87236476234', no_exception: true)
    expect(res).to be false

    res = Messaging::PhoneValidation.validate_sms_number_format('+872.364.76234', no_exception: true)
    expect(res).to be false
  end

  it 'gets user SMS numbers from a query of users' do
    u1, = create_user
    u2, = create_user
    u3, = create_user

    @message_notification.recipient_user_ids = [u1.id, u2.id, u3.id]

    nums = @message_notification.recipient_sms_numbers

    expect(nums.length).to eq 0

    Users::ContactInfo.create! sms_number: '+1-202-555-0147', user: u2, current_admin: @admin

    expect do
      Users::ContactInfo.create! sms_number: '12025550147', user: u1, current_admin: @admin
    end.to raise_error ActiveRecord::RecordInvalid

    Users::ContactInfo.create! sms_number: '+12025550147', user: u1, current_admin: @admin

    @message_notification.reset_recipients!
    nums = @message_notification.recipient_sms_numbers
    expect(nums.length).to eq 1
    expect(nums[0]).to eq '+12025550147'

    Users::ContactInfo.create! sms_number: '+1-202-555-0156', user: u3, current_admin: @admin
    @message_notification.reset_recipients!
    nums = @message_notification.recipient_sms_numbers
    expect(nums.length).to eq 2
    expect(nums).to include '+12025550147'
    expect(nums).to include '+12025550156'

    sms = Messaging::NotificationSms.new
    mock_send_sms_response sms

    sms.send_now @message_notification
  end

  it 'sends an sms' do
    @message_notification.reset_recipients!

    expect(@message_notification.recipient_sms_numbers).to be_empty

    expect do
      sms = Messaging::NotificationSms.new
      sms.send_now @message_notification
    end.to raise_error(FphsException, 'No recipients to SMS')

    u1, = create_user
    u2, = create_user
    u3, = create_user

    u1.create_contact_info! sms_number: '+12025550146', current_admin: u1.admin

    @message_notification.recipient_user_ids = [u1.id, u2.id, u3.id]
    sms = Messaging::NotificationSms.new
    mock_send_sms_response sms
    sms.send_now @message_notification

    @message_notification.recipient_sms_numbers = ['+12025550147']
    sms = Messaging::NotificationSms.new
    # No mock - send a real one to be sure
    sms.send_now @message_notification

    expect(sms).not_to be nil
  end

  it 'sends an sms with promotional importance' do
    @message_notification.importance = 'Promotional'
    # This is a known bad number
    @message_notification.recipient_sms_numbers = ['+12025550147']
    sms = Messaging::NotificationSms.new
    mock_send_sms_response sms
    sms.send_now @message_notification

    expect(sms).not_to be nil
  end

  it 'tests timing on send' do
    @message_notification.importance = 'Promotional'
    # This is a known bad number
    @message_notification.recipient_sms_numbers = ['+12025550147']

    sms = Messaging::NotificationSms.new
    mock_send_sms_response sms

    t = Benchmark.realtime do
      3.times do
        sms.send_now @message_notification
      end
    end

    puts "Done in #{t} seconds"

    expect(t).to be < 3
  end
end
