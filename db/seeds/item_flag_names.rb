module Seeds
  module ItemFlagNames

    def self.add_values values
      values.each do |v|
        res = Classification::ItemFlagName.find_or_initialize_by(v)
        res.update(current_admin: auto_admin) unless res.admin
      end

    end

    def self.create_item_flag_names
      
      
      values = [
      {name: "follow up - email",item_type: "player_info"},
      {name: "follow up - CIS",item_type: "player_info"},
      {name: "follow up - ambassador",item_type: "player_info"}
      ]
      
      
      add_values values
      
      Rails.logger.info "#{self.name} = #{Classification::ItemFlagName.all.length}"
    end
    
    
    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || Classification::ItemFlagName.count == 0
        if Classification::Protocol.count == 0 || Classification::Protocol.where(name: 'Updates').count == 0
          Seeds::ATrackerUpdatesProtocol.create_protocol_events
        end
        create_item_flag_names 
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
