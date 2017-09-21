module ActivityLogSetup

  include ModelSupport

  def create_phone_log_config
    admin, _ = create_admin
    if ActivityLog.enabled.where(name: "Phone Log").length == 0
      ActivityLog.create!(name: 'Phone Log', item_type: 'player_contact', rec_type: 'phone', current_admin: admin, disabled: false, action_when_attribute: 'called_when')
    end

    if GeneralSelection.enabled.where(item_type: 'activity_log_player_contact_phone_select_call_direction').length == 0

      gs = [
        ["To Player", "to player", "activity_log_player_contact_phone_select_call_direction"],
        ["To Staff", "to staff", "activity_log_player_contact_phone_select_call_direction"],
        ["Complete", "complete", "activity_log_player_contact_phone_select_next_step"],
        ["Complete (Unsuccessful)", "complete (unsuccessful)", "activity_log_player_contact_phone_select_next_step"],
        ["Call Back", "call back", "activity_log_player_contact_phone_select_next_step"],
        ["No Follow Up", "no follow up", "activity_log_player_contact_phone_select_next_step"],
        ["More Info Requested", "more info requested", "activity_log_player_contact_phone_select_next_step"],
        ["Do Not Call This Number", "do not call this number", "activity_log_player_contact_phone_select_next_step"],
        ["Do Not Call Any Number", "do not call any number", "activity_log_player_contact_phone_select_next_step"],
        ["Call Connected", "connected", "activity_log_player_contact_phone_select_result"],
        ["Left Voicemail", "voicemail", "activity_log_player_contact_phone_select_result"],
        ["Not Connected", "not connected", "activity_log_player_contact_phone_select_result"],
        ["Bad Number", "bad number", "activity_log_player_contact_phone_select_result"],
        ["Me", "user", "activity_log_player_contact_phone_select_who"],
        ["Rob Standish", "rob standish", "activity_log_player_contact_phone_select_who"],
        ["Chris", "chris", "activity_log_player_contact_phone_select_who"],
        ["P Smith", "p smith", "activity_log_player_contact_phone_select_who"],
        ["Andy Morehouse", "andy morehouse", "activity_log_player_contact_phone_select_who"]
      ]
      gs.each do |g|
        GeneralSelection.create!(name: g[0], value: g[2], item_type: g[2], current_admin: admin, disabled: false, create_with: true, edit_always: true)
      end
    end
  end
end

World(ActivityLogSetup)