module ActivityLogSetup

  include ModelSupport

  # Most of the database items are set up in the DB seed. This method just allows for some additional
  # test specific items to be added
  def create_phone_log_config
    admin, _ = create_admin
    
    if GeneralSelection.enabled.where(item_type: 'activity_log_player_contact_phone_select_who').length >= 5

      gs = [
        ["Rob Standish", "rob standish", "activity_log_player_contact_phone_select_who"],
        ["Chris", "chris", "activity_log_player_contact_phone_select_who"],
        ["P Smith", "p smith", "activity_log_player_contact_phone_select_who"],
        ["Andy Morehouse", "andy morehouse", "activity_log_player_contact_phone_select_who"]
      ]
      gs.each do |g|
        GeneralSelection.create!(name: g[0], value: g[2], item_type: g[2], current_admin: admin, disabled: false, create_with: true, edit_always: false, lock: true )
      end
    end
  end
end

World(ActivityLogSetup)