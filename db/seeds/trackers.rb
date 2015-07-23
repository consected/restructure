module Seeds
  module Trackers

    def self.create_tracker_updates    
      
      protocol = Protocol.find_or_initialize_by(name: 'Updates')
      protocol.update(admin: auto_admin) unless protocol.admin

      fu = protocol.sub_processes.find_or_initialize_by(name: 'flag updates')
      fu.update(admin: auto_admin) unless fu.admin
      
      sub_process = protocol.sub_processes.find_or_initialize_by(name: 'record updates')
      sub_process.update(admin: auto_admin) unless sub_process.admin
      
      res = sub_process.protocol_events.find_or_initialize_by(name: 'updated player info')
      res.update(admin: auto_admin) unless res.admin
      res = sub_process.protocol_events.find_or_initialize_by(name: 'updated player contact')
      res.update(admin: auto_admin) unless res.admin
      res = sub_process.protocol_events.find_or_initialize_by(name: 'updated address')
      res.update(admin: auto_admin) unless res.admin

      res = sub_process.protocol_events.find_or_initialize_by(name: 'created player info')
      res.update(admin: auto_admin) unless res.admin
      res = sub_process.protocol_events.find_or_initialize_by(name: 'created player contact')
      res.update(admin: auto_admin) unless res.admin
      res = sub_process.protocol_events.find_or_initialize_by(name: 'created address')
      res.update(admin: auto_admin) unless res.admin

      Rails.logger.info "Updates > Protocol events = #{sub_process.protocol_events.length}"
    end


    def self.setup
      Rails.logger.info "Calling #{self}.setup"
      
      create_tracker_updates
    end

  end
  
  Trackers
  
end