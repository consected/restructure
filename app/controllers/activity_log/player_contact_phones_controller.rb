class ActivityLog::PlayerContactPhonesController < ActivityLog::ActivityLogsController

  def item_controller
    "player_contacts"
  end

  def item_rec_type
    'phone'
  end



end
