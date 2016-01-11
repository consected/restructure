module Seeds
  module TrackerUpdatesProtocol

    def self.add_values values, sub_process
      values.each do |v|
        res = sub_process.protocol_events.find_or_initialize_by(v)
        res.update!(current_admin: auto_admin) unless res.admin
      end
    end

    def self.create_protocol_events
      
      protocol = Protocol.find_or_initialize_by(name: 'Updates')
      protocol.current_admin = auto_admin
      protocol.position = 100
      protocol.save!
      sp = protocol.sub_processes.find_or_initialize_by(name: 'record updates')
      sp.current_admin = auto_admin
      sp.save!
      
      values = [
        {name: "created address", sub_process_id: sp.id},
        {name: "created player contact", sub_process_id: sp.id},
        {name: "created player info", sub_process_id: sp.id},
        {name: "created scantron", sub_process_id: sp.id},
        {name: "created sage assignment", sub_process_id: sp.id},
        {name: "updated address", sub_process_id: sp.id},
        {name: "updated player contact", sub_process_id: sp.id},
        {name: "updated player info", sub_process_id: sp.id},
        {name: "updated scantron", sub_process_id: sp.id},
        {name: "updated sage assignment", sub_process_id: sp.id}  
      ]
      
      add_values values, sp
      
      
      sp = protocol.sub_processes.find_or_initialize_by(name: 'flag updates')
      sp.current_admin = auto_admin
      sp.save!
      values = [        
        {name: "created player info", sub_process_id: sp.id},        
        {name: "updated player info", sub_process_id: sp.id}
      ]
      
      add_values values, sp
      
      
      
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
