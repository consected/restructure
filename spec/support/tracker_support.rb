require 'support/master_support'
module TrackerSupport
  include MasterSupport
  
  def self.create_tracker_updates    
    admin, pw = ControllerMacros.create_admin 
    
    protocol = Protocol.create! name: 'Updates', admin: admin
        
    sub_process = protocol.sub_processes.build name: 'record updates', admin: admin
    sub_process.save!
    
    sub_process.protocol_events.create name: 'updated player info', admin: admin
    sub_process.protocol_events.create name: 'updated contact info', admin: admin
    sub_process.protocol_events.create name: 'updated address info', admin: admin
    
    
  end
  
  def create_tracker_updates
    TrackerSupport.create_tracker_updates
  end
  
   
end
