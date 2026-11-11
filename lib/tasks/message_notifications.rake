# frozen_string_literal: true

# Backfill tracker entries (General > Notification > Sent / Failed) for message notifications that were
# sent or failed before automatic tracker entries were introduced (issue #1479).
#
# Usage (run once after deploying the feature; safe to re-run):
#
#   bundle exec rails "message_notifications:backfill_tracker_entries[batch_size,from_id]"
#
# Arguments (both optional):
#   batch_size - number of notifications loaded per batch, and how often progress is printed. Default 250.
#   from_id    - only process notifications with id >= from_id, to resume after an interrupted run.
#
# Behaviour:
#   - Only notifications with status 'complete' or 'failed' are examined.
#   - User-addressed notifications (recipient user IDs or role_name) are ignored because they are internal alerts.
#   - Targeting follows the live rules: the notification master, or recipient / list item matching when there
#     is no usable master. Holding masters (Master::TemporaryMasterIds) are never a target.
#   - Existing entries for a notification and master are skipped, so re-running does not create duplicates
#     and completes any targets missed by an earlier partial run.
#   - The event date is the notification updated_at. Notifications are not modified.
#   - Legacy no_tracker_entry opt-outs cannot be distinguished; otherwise eligible participant notifications may get entries.
#   - Requires the General > Notification > Sent / Failed records (rails db:seed or the migration
#     20261027120000); the task aborts with a message if they are missing.
#   - Run while message sending is quiet. A notification that completes mid-run can also receive its entry from
#     the live callback, and the two are not locked against each other, so a duplicate entry is possible.
#
# Output: the number of notifications to examine, a progress line every batch_size notifications, and a final
# "Backfill complete: ..." summary line with the examined, created, skipped, ignored and failure counts. If any
# notification fails, its id is listed and the task exits with a non-zero status after processing the rest.
namespace :message_notifications do
  desc 'Backfill tracker entries for completed and failed message notifications'
  task :backfill_tracker_entries, %i[batch_size from_id] => :environment do |_task, args|
    begin
      batch_size = Integer(args[:batch_size].presence || 250)
      raise ArgumentError unless batch_size.positive?
    rescue ArgumentError
      abort 'batch_size must be a positive integer'
    end

    from_id = args[:from_id].presence
    begin
      from_id = Integer(from_id) if from_id
    rescue ArgumentError
      abort 'from_id must be an integer'
    end

    protocol = Classification::Protocol.active.find_by(name: 'General')
    notification = protocol && protocol.sub_processes.active.find_by(name: 'Notification')
    required_events = %w[Sent Failed]
    existing_events = if notification
                        notification.protocol_events.active.where(name: required_events).pluck(:name)
                      else
                        []
                      end
    missing_events = required_events - existing_events
    unless protocol && notification && missing_events.empty?
      abort 'General > Notification > Sent/Failed tracker records are required. ' \
            'Run rails db:seed or rails db:migrate VERSION=20261027120000 first.'
    end

    notifications = Messaging::MessageNotification.where(status: %w[complete failed])
    notifications = notifications.where('id >= ?', from_id) if from_id

    puts "Backfilling tracker entries: #{notifications.count} notification(s) to examine."

    examined = 0
    created = 0
    skipped = 0
    ignored = 0
    failures = 0
    failed_notification_ids = []

    notifications.find_each(batch_size:) do |message_notification|
      result = Messaging::MessageNotificationTracker.create_for(
        message_notification, skip_existing: true, strict: true
      )
      created += result.created
      skipped += result.skipped
      ignored += result.ignored
    rescue Messaging::MessageNotificationTracker::TargetCreationError => e
      created += e.result.created
      skipped += e.result.skipped
      ignored += e.result.ignored
      failures += e.result.failed
      failed_notification_ids << message_notification.id
      e.result.errors.each do |failure|
        target = failure[:master_id] ? "master #{failure[:master_id]}" : 'notification'
        error = failure[:error]
        warn "Unable to backfill notification #{message_notification.id} for #{target}: " \
             "#{error.class}: #{error.message}"
      end
    rescue StandardError => e
      failures += 1
      failed_notification_ids << message_notification.id
      warn "Unable to backfill notification #{message_notification.id}: #{e.class}: #{e.message}"
    ensure
      examined += 1
      if (examined % batch_size).zero?
        puts "Examined #{examined} notification(s); created #{created} tracker entry/entries; " \
             "skipped #{skipped} existing target(s); " \
             "ignored #{ignored} notification(s) because they were addressed to users; failures #{failures}."
      end
    end

    puts "Backfill complete: #{examined} notification(s) examined; #{created} tracker entry/entries created; " \
         "#{skipped} target(s) skipped because an entry already existed; " \
         "#{ignored} notification(s) ignored because they were addressed to users; #{failures} failure(s)."
    puts "Failed notification ids: #{failed_notification_ids.uniq.join(', ')}" if failed_notification_ids.any?
    abort 'Message notification tracker backfill completed with failures' if failures.positive?
  end
end
