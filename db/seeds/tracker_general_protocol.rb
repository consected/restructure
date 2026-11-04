# frozen_string_literal: true

module Seeds
  module TrackerGeneralProtocol
    def self.add_values(values, sub_process)
      values.each do |v|
        res = sub_process.protocol_events.active.find_or_initialize_by(v)
        res.update!(current_admin: Seeds.auto_admin) unless res.admin
      end
    end

    def self.create_protocol_events
      protocol = Classification::Protocol.active.find_or_initialize_by(name: 'General')
      protocol.current_admin = Seeds.auto_admin
      protocol.position = 50
      protocol.save!
      sp = protocol.sub_processes.active.find_or_initialize_by(name: 'Communications')
      sp.current_admin = Seeds.auto_admin
      sp.save!

      values = [
        { name: 'communication (incoming)' },
        { name: 'communication (outgoing)' }
      ]

      add_values values, sp

      notification = protocol.sub_processes.active.find_or_initialize_by(name: 'Notification')
      notification.current_admin = Seeds.auto_admin
      notification.save!

      notification_values = [
        { name: 'Sent' },
        { name: 'Failed' }
      ]

      add_values notification_values, notification
    end

    def self.notification_events_missing?
      protocol = Classification::Protocol.active.find_by(name: 'General')
      return true unless protocol

      notification = protocol.sub_processes.active.find_by(name: 'Notification')
      return true unless notification

      required_events = %w[Sent Failed]
      active_events = notification.protocol_events.active.where(name: required_events).pluck(:name)
      (required_events - active_events).any?
    end

    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || notification_events_missing?
        create_protocol_events
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
