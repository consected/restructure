# frozen_string_literal: true

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

    examined = 0
    created = 0
    skipped = 0
    failures = 0
    failed_notification_ids = []

    notifications.find_each(batch_size:) do |message_notification|
      result = Messaging::MessageNotificationTracker.create_for(
        message_notification, skip_existing: true, strict: true
      )
      created += result.created
      skipped += result.skipped
    rescue Messaging::MessageNotificationTracker::TargetCreationError => e
      created += e.result.created
      skipped += e.result.skipped
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
             "skipped #{skipped} existing target(s); failures #{failures}."
      end
    end

    puts "Backfill complete: #{examined} notification(s) examined; #{created} tracker entry/entries created; " \
         "#{skipped} target(s) skipped because an entry already existed; #{failures} failure(s)."
    puts "Failed notification ids: #{failed_notification_ids.uniq.join(', ')}" if failed_notification_ids.any?
    abort 'Message notification tracker backfill completed with failures' if failures.positive?
  end
end
