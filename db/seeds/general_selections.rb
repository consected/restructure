module Seeds
  module GeneralSelections

    def self.add_values values, item_type
      values.each do |v|
        res = Classification::GeneralSelection.find_or_initialize_by( v.merge(item_type: item_type))
        # Fails quietly if the item_type / value is a duplicate, independent of other attributes (name, lock, edit_always, etc)
        res.update(current_admin: auto_admin) unless res.admin
      end

    end

    def self.create_player_infos_source
      item_type = 'player_infos_source'

      values = [
        {name: 'NFLPA', value: 'nflpa', create_with: true, lock: true},
        {name: 'NFLPA 2', value: 'nflpa2', create_with: true, lock: true}
      ]

      add_values values, item_type
      Rails.logger.info "#{self.name} for #{item_type} = #{Classification::GeneralSelection.where(item_type: item_type).length}"
    end


    def self.create_player_contacts_rank

      item_type = 'player_contacts_rank'

      values = [
        {name: 'primary', value: 10, create_with: true, edit_always: true},
        {name: 'secondary', value: 5, create_with: true, edit_always: true},
        {name: 'do not use', value: 0, create_with: true, edit_always: true},
        {name: 'bad contact', value: -1, create_with: true, edit_always: true}
      ]

      add_values values, item_type

      Rails.logger.info "#{self.name} for #{item_type} = #{Classification::GeneralSelection.where(item_type: item_type).length}"
    end

    def self.create_player_contacts_source
      item_type = 'player_contacts_source'

      values = [
        {name: 'NFL', value: 'nfl', create_with: true, lock: true},
        {name: 'NFLPA', value: 'nflpa', create_with: true, lock: true}
      ]

      add_values values, item_type
      Rails.logger.info "#{self.name} for #{item_type} = #{Classification::GeneralSelection.where(item_type: item_type).length}"
    end

    def self.create_addresses_source
      item_type = 'addresses_source'

      values = [
        {name: 'NFL', value: 'nfl', create_with: true, lock: true},
        {name: 'NFLPA', value: 'nflpa', create_with: true, lock: true}
      ]

      add_values values, item_type
      Rails.logger.info "#{self.name} for #{item_type} = #{Classification::GeneralSelection.where(item_type: item_type).length}"
    end

    def self.create_addresses_rank

      item_type = 'addresses_rank'

      values = [
        {name: 'primary', value: 10, create_with: true, edit_always: true},
        {name: 'secondary', value: 5, create_with: true, edit_always: true},
        {name: 'do not use', value: 0, create_with: true, edit_always: true},
        {name: 'bad contact', value: -1, create_with: true, edit_always: true}
      ]

      add_values values, item_type

      Rails.logger.info "#{self.name} for #{item_type} = #{Classification::GeneralSelection.where(item_type: item_type).length}"
    end

    def self.create_player_contacts_type

      item_type = 'player_contacts_type'

      values = [
        {name: 'Email', value: 'email', create_with: true, lock: true},
        {name: 'Phone', value: 'phone', create_with: true, lock: true}
      ]

      add_values values, item_type

      Rails.logger.info "#{self.name} for #{item_type} = #{Classification::GeneralSelection.where(item_type: item_type).length}"
      raise "Bad Seed! #{PlayerContact.valid_rec_types}" unless PlayerContact.valid_rec_types.length > 0
    end


    def self.setup
      log "In #{self}.setup"

      if Rails.env.test? || Classification::GeneralSelection.where(item_type: 'player_infos_source').length == 0
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
