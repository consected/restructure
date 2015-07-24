module Seeds
  module GeneralSelections

    def self.add_values values, item_type
      values.each do |v|
        res = GeneralSelection.find_or_initialize_by( v.merge(item_type: item_type))
        res.update(admin: auto_admin) unless res.admin
      end

    end
    
    def self.create_player_contacts_rank
      
      item_type = 'player_contacts_rank'
      
      values = [
        {name: 'primary', value: 10},
        {name: 'secondary', value: 5},
        {name: 'inactive', value: 0},
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
        {name: 'inactive', value: 0},
        {name: 'bad contact', value: -1}
      ]
      
      add_values values, item_type
      
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"
    end

    def self.setup
      Rails.logger.info "Calling #{self}.setup"
      
      create_player_contacts_rank
      create_player_contacts_source
      create_addresses_source
      create_addresses_rank
    end

  end
  
  Trackers
  
end