module Seeds
  module Trackers

    def self.create_tracker_updates
      Rails.logger.info  "Seeding tracker updates"
      protocol = Classification::Protocol.active.find_or_initialize_by(name: 'Updates')
      protocol.update(current_admin: auto_admin) unless protocol.admin

      fu = protocol.sub_processes.find_or_initialize_by(name: 'flag updates')
      fu.update(current_admin: auto_admin) unless fu.admin

      sub_process = protocol.sub_processes.find_or_initialize_by(name: 'record updates')
      sub_process.update(current_admin: auto_admin) unless sub_process.admin

      types = ['player info', 'player contact', 'address', 'scantron']

      types.each do |t|
        res = sub_process.protocol_events.find_or_initialize_by(name: "updated #{t}")
        res.update(current_admin: auto_admin) unless res.admin

        res = sub_process.protocol_events.find_or_initialize_by(name: "created #{t}")
        res.update(current_admin: auto_admin) unless res.admin
      end

      types.each do |t|
        res = fu.protocol_events.find_or_initialize_by(name: "updated #{t}")
        res.update(current_admin: auto_admin) unless res.admin

        res = fu.protocol_events.find_or_initialize_by(name: "created #{t}")
        res.update(current_admin: auto_admin) unless res.admin
      end


      Rails.logger.info  "Updates > Classification::Protocol events = #{sub_process.protocol_events.collect {|k| k.name }.join(",") }"
      Rails.logger.info  "Flag Updates > Classification::Protocol events = #{fu.protocol_events.collect {|k| k.name }.join(",") }"
    end


    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || Classification::Protocol.active.count == 0
        create_tracker_updates
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end

    end

  end

  Trackers

end
