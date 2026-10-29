# frozen_string_literal: true

# Purpose: Verify tracker history follows real notification status transitions, including SMS failures with no resolved recipients.
require 'rails_helper'

RSpec.describe Messaging::MessageNotification, type: :model do
  include MasterSupport

  before :example do
    create_admin
    seed_database
    Seeds::TrackerGeneralProtocol.create_protocol_events
    @owner_user, = create_user
    @recipient_user, = create_user
    @master = create_master(@owner_user)
    @sms_layout = Admin::MessageTemplate.create!(
      name: "tracker sms layout #{SecureRandom.hex(5)}",
      message_type: :sms,
      template_type: :layout,
      template: '{{main_content}}',
      current_admin: @admin
    )
  end

  it 'creates a Failed master history when SMS users have no phone numbers' do
    notification = described_class.create!(
      user: @owner_user,
      master: @master,
      recipient_user_ids: [@recipient_user],
      layout_template_name: @sms_layout.name,
      content_template_text: 'Notification content',
      message_type: :sms
    )
    expect(notification.recipient_sms_numbers).to be_empty

    expect do
      HandleMessageNotificationJob.perform_now(notification)
    end.to raise_error(FphsException, /No recipients to SMS/)

    history = TrackerHistory.where(item_type: notification.class.name, item_id: notification.id).sole
    event = Classification::ProtocolEvent.find(history.protocol_event_id)
    expect(event.name).to eq 'Failed'
    expect(history.master_id).to eq @master.id
    expect(history.notes).to eq 'type: sms'
    expect(history.record_type).to eq notification.class.name
    expect(history.record_id).to eq notification.id
    expect(history.user_id).to eq @owner_user.id
    expect(history.event_date).to eq notification.reload.updated_at
  end
end
