module Seeds
  module TrackerAlertsProtocol

    def self.add_values values, sub_process
      values.each do |v|
        res = sub_process.protocol_events.find_or_initialize_by(v)
        res.update!(current_admin: auto_admin) unless res.admin
      end
    end

    def self.create_protocol_events
      
      protocol = Protocol.find_or_initialize_by(name: 'Study')
      protocol.current_admin = auto_admin
      protocol.position = 10
      protocol.save!
      sp = protocol.sub_processes.find_or_initialize_by(name: 'Alerts')
      sp.current_admin = auto_admin
      sp.save!
      
      values = [
        {name: "Level 1", disabled: false, sub_process_id: sp.id, milestone: "always-notify-user", description: " It is strongly recommended to avoid contact with this person. If receiving a call, attempt to redirect to a supervisor immediately."},
        {name: "Level 2", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil},
        {name: "Level 3", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil},
        {name: "Resolved", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil}
      ]
      
      add_values values, sp
      
      
      sp = protocol.sub_processes.find_or_initialize_by(name: 'Opt Out')
      sp.current_admin = auto_admin
      sp.save!
      
      
    end
    
    
    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || Protocol.count == 0
        create_protocol_events
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
      
    end
  end
end
