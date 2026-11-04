# frozen_string_literal: true

class AddNotificationProtocolEventsToTrackerGeneralProtocol < ActiveRecord::Migration[7.1]
  def up
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

  private

  def migration_admin
    @migration_admin ||= Admin.active.find_by(email: Settings::AdminEmail.downcase) || Admin.active.first ||
                         raise('An active admin is required to run this migration')
  end
end
