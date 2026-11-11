# frozen_string_literal: true

require 'rails_helper'

# Verifies the non-persisted tracker-entry option is forwarded by the notification job.
RSpec.describe HandleMessageNotificationJob, type: :job do
  it 'forwards no_tracker_entry to the notification handler' do
    notification = instance_double(Messaging::MessageNotification)

    expect(notification).to receive(:handle_notification_now).with(
      logger: Delayed::Worker.logger,
      for_item: nil,
      on_complete_config: nil,
      alt_batch_user: nil,
      ignore_no_recipients: nil,
      no_tracker_entry: true
    )

    described_class.perform_now(notification, no_tracker_entry: true)
  end
end
