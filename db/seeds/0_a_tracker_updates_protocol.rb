module Seeds
  module ATrackerUpdatesProtocol
    def self.do_first
      true
    end

    def self.add_values(values, sub_process)
      values.each do |v|
        res = sub_process.protocol_events.find_or_initialize_by(v)
        res.update!(current_admin: Seeds.auto_admin, disabled: false) unless res.admin && !res.disabled
      end
    end

    def self.create_protocol_events
      protocol = Classification::Protocol.active.reload.find_or_initialize_by(name: 'Updates')
      protocol.current_admin = Seeds.auto_admin
      protocol.position = 100
      protocol.save!
      sp = protocol.sub_processes.active.reload.find_or_initialize_by(name: 'record updates')
      sp.current_admin = Seeds.auto_admin
      sp.save!

      values = [
        { name: 'created address', sub_process_id: sp.id },
        { name: 'created player contact', sub_process_id: sp.id },
        { name: 'created player info', sub_process_id: sp.id },
        { name: 'created scantron', sub_process_id: sp.id },
        { name: 'created sage assignment', sub_process_id: sp.id },
        { name: 'updated address', sub_process_id: sp.id },
        { name: 'updated player contact', sub_process_id: sp.id },
        { name: 'updated player info', sub_process_id: sp.id },
        { name: 'updated scantron', sub_process_id: sp.id },
        { name: 'updated sage assignment', sub_process_id: sp.id },

        { name: 'created nfs store  manage  container', sub_process_id: sp.id },
        { name: 'updated nfs store  manage  container', sub_process_id: sp.id },
        { name: 'created nfs store  manage  stored file', sub_process_id: sp.id },
        { name: 'updated nfs store  manage  stored file', sub_process_id: sp.id },
        { name: 'created nfs store  manage  archived file', sub_process_id: sp.id },
        { name: 'updated nfs store  manage  archived file', sub_process_id: sp.id }

      ]

      add_values values, sp

      sp = protocol.sub_processes.active.reload.find_or_initialize_by(name: 'flag updates')
      sp.current_admin = Seeds.auto_admin
      sp.save!
      values = [
        { name: 'created player info', sub_process_id: sp.id },
        { name: 'updated player info', sub_process_id: sp.id }
      ]

      add_values values, sp
    end

    def self.setup
      log "In #{self}.setup"
      log "Updates: #{Classification::Protocol.active.where(name: 'Updates').count}"
      if Rails.env.test? || Classification::Protocol.active.reload.where(name: 'Updates').count == 0
        create_protocol_events
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
