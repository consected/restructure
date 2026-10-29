# frozen_string_literal: true

class BackfillMessageNotificationTrackerHistory < ActiveRecord::Migration[7.1]
  BATCH_SIZE = 250
  NOTIFICATION_ITEM_TYPE = 'Messaging::MessageNotification'

  def up
    ensure_notification_protocol_events

    existing_item_ids = TrackerHistory.where(item_type: NOTIFICATION_ITEM_TYPE)
                                      .where.not(item_id: nil)
                                      .select(:item_id)
    notifications = Messaging::MessageNotification
                    .where(status: %w[complete failed])
                    .where.not(id: existing_item_ids)

    total = notifications.count
    say "Backfilling tracker history for #{total} message notification(s)"

    processed = 0
    failures = 0
    notifications.find_each(batch_size: BATCH_SIZE) do |notification|
      begin
        Messaging::MessageNotificationTracker.create_for(notification)
      rescue StandardError => e
        failures += 1
        say "Unable to backfill message notification #{notification.id}: #{e.class}: #{e.message}"
      end
      processed += 1
    end

    say "Processed #{processed} message notification(s); #{failures} failed"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'Backfilled rows cannot be distinguished from tracker history created by live notifications.'
  end

  private

  def ensure_notification_protocol_events
    protocol = Classification::Protocol.active.find_by(name: 'General')
    unless protocol
      protocol = Classification::Protocol.new(name: 'General', position: 50)
      protocol.current_admin = migration_admin
      protocol.save!
    end

    notification = protocol.sub_processes.active.find_by(name: 'Notification')
    unless notification
      notification = protocol.sub_processes.build(name: 'Notification')
      notification.current_admin = migration_admin
      notification.save!
    end

    %w[Sent Failed].each do |event_name|
      next if notification.protocol_events.active.exists?(name: event_name)

      event = notification.protocol_events.build(name: event_name)
      event.current_admin = migration_admin
      event.save!
    end
  end

  def migration_admin
    @migration_admin ||= Admin.active.find_by(email: Settings::AdminEmail.downcase) || Admin.active.first ||
                         raise('An active admin is required to run this migration')
  end
end
