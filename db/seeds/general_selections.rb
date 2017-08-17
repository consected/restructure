module Seeds
  module GeneralSelections

    def self.add_values values, item_type
      values.each do |v|
        res = GeneralSelection.find_or_initialize_by( v.merge(item_type: item_type))
        res.update(current_admin: auto_admin) unless res.admin
      end

    end

    def self.create_player_infos_source
      item_type = 'player_infos_source'
      
      values = [        
        {name: 'NFLPA', value: 'nflpa'},
        {name: 'NFLPA 2', value: 'nflpa2'}
      ]
      
      add_values values, item_type
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"
    end

    
    def self.create_player_contacts_rank
      
      item_type = 'player_contacts_rank'
      
      values = [
        {name: 'primary', value: 10},
        {name: 'secondary', value: 5},
        {name: 'do not use', value: 0},
        {name: 'bad contact', value: -1}
      ]
      
      add_values values, item_type
      
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"
    end
    
    def self.create_player_contacts_source
      item_type = 'player_contacts_source'
      
      values = [
        {name: 'NFL', value: 'nfl'},
        {name: 'NFLPA', value: 'nflpa'}                
      ]
      
      add_values values, item_type
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"
    end

    def self.create_addresses_source
      item_type = 'addresses_source'
      
      values = [
        {name: 'NFL', value: 'nfl'},
        {name: 'NFLPA', value: 'nflpa'}                
      ]
      
      add_values values, item_type
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"
    end
    
    def self.create_addresses_rank
      
      item_type = 'addresses_rank'
      
      values = [
        {name: 'primary', value: 10},
        {name: 'secondary', value: 5},
        {name: 'do not use', value: 0},
        {name: 'bad contact', value: -1}
      ]
      
      add_values values, item_type
      
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"
    end

    def self.create_player_contacts_type
      
      item_type = 'player_contacts_type'
      
      values = [
        {name: 'Email', value: 'email'},
        {name: 'Phone', value: 'phone'}                
      ]
      
      add_values values, item_type
      
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"
    end
    
    
    def self.setup
      log "In #{self}.setup"

      if Rails.env.test? || GeneralSelection.count == 0
        create_player_infos_source

        create_player_contacts_rank
        create_player_contacts_source
        create_player_contacts_type
        create_addresses_source
        create_addresses_rank
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end

  end
  
  
end