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
      no_tracker_entry: true,
      require_email_sent: nil
    )

    described_class.perform_now(notification, no_tracker_entry: true)
  end

  it 'forwards require_email_sent to the notification handler' do
    notification = instance_double(Messaging::MessageNotification)

    expect(notification).to receive(:handle_notification_now).with(
      hash_including(require_email_sent: true)
    )

    described_class.perform_now(notification, require_email_sent: true)
  end
end
