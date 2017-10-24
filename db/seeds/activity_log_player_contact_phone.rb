module Seeds
  module ActivityLogPlayerContactPhone

    def self.add_values values, item_type
      values.each do |v|
        res = GeneralSelection.find_or_initialize_by( v.merge(item_type: item_type))
        res.update(current_admin: auto_admin) unless res.admin
      end
    end

    def self.create_phone_log_admin_activity_log

      res = ActivityLog.find_or_initialize_by(name: 'Phone Log', item_type: 'player_contact', rec_type: 'phone', disabled: false, action_when_attribute: 'called_when')
      res.update(current_admin: auto_admin) unless res.admin

    end


    def self.create_phone_log_general_selections

      item_type = "activity_log__player_contact_phone_select_call_direction"

      values = [
        {name: "To Player", value: "to player", create_with: true, lock: true},
        {name: "To Staff", value: "to staff", create_with: true, lock: true}
      ]

      add_values values, item_type
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"


      item_type = "activity_log__player_contact_phone_select_next_step"
      values = [
        {name: "Complete", value: "complete", create_with: true, lock: true},
        {name: "Call Back", value: "call back", create_with: true, lock: true},
        {name: "No Follow Up", value: "no follow up", create_with: true, lock: true},
        {name: "More Info Requested", value: "more info requested", create_with: true, lock: true}
      ]
      add_values values, item_type
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"

      item_type = "activity_log__player_contact_phone_select_result"
      values = [
        {name: "Connected", value: "connected", create_with: true, lock: true},
        {name: "Left Voicemail", value: "voicemail", create_with: true, lock: true},
        {name: "Not Connected", value: "not connected", create_with: true, lock: true},
        {name: "Bad Number", value: "bad number", create_with: true, lock: true}
      ]
      add_values values, item_type
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"


      item_type = "activity_log__player_contact_phone_select_who"
      values = [
        {name: "Me", value: "user", create_with: true, lock: true}
      ]
      add_values values, item_type
      Rails.logger.info "#{self.name} for #{item_type} = #{GeneralSelection.where(item_type: item_type).length}"

    end

    def self.setup
      log "In #{self}.setup"

      if Rails.env.test? || GeneralSelection.where(item_type: "activity_log__player_contact_phone_select_call_direction").length == 0

        create_phone_log_general_selections
        create_phone_log_admin_activity_log
      end
    end

  end
end
