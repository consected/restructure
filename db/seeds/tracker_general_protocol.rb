module Seeds
  module TrackerGeneralProtocol

    def self.add_values values, sub_process
      values.each do |v|
        res = sub_process.protocol_events.find_or_initialize_by(v)
        res.update!(current_admin: auto_admin) unless res.admin
      end
    end

    def self.create_protocol_events

      protocol = Protocol.active.find_or_initialize_by(name: 'General')
      protocol.current_admin = auto_admin
      protocol.position = 50
      protocol.save!
      sp = protocol.sub_processes.find_or_initialize_by(name: 'Communications')
      sp.current_admin = auto_admin
      sp.save!

      values = [
        {name: "communication (incoming)", disabled: false, sub_process_id: sp.id, milestone: nil, description: nil},
        {name: "communication (outgoing)", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil}
      ]

      add_values values, sp

    end


    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || Protocol.active.count == 0
        create_protocol_events
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end

    end
  end
end
