class AddTrackerIdToActivityLogPlayerContactPhones < ActiveRecord::Migration
  def change
    add_reference :activity_log_player_contact_phones, :tracker, index: true, foreign_key: true
  end
end
