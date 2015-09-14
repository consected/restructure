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
        {name: "created address", disabled: false, sub_process_id: sp.id, milestone: nil, description: nil},
        {name: "created player contact", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil},
        {name: "created player info", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil},
        {name: "created scantron", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil},
        {name: "updated address", disabled: false, sub_process_id: sp.id, milestone: nil, description: nil},
        {name: "updated player contact", disabled: false, sub_process_id: sp.id, milestone: nil, description: nil},
        {name: "updated player info", disabled: false, sub_process_id: sp.id, milestone: nil, description: nil},
        {name: "updated scantron", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil}  
      ]
      
      add_values values, sp
      
      
      sp = protocol.sub_processes.find_or_initialize_by(name: 'flag updates')
      sp.current_admin = auto_admin
      sp.save!
      values = [        
        {name: "created player info", disabled: nil, sub_process_id: sp.id, milestone: nil, description: nil},        
        {name: "updated player info", disabled: false, sub_process_id: sp.id, milestone: nil, description: nil}
      ]
      
      add_values values, sp
      
      
      
    end
    
    
    def self.setup
      Rails.logger.info "Calling #{self}.setup"
      
      create_protocol_events
    end
  end
end
