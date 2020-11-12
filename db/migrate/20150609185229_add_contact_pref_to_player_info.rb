class AddContactPrefToPlayerInfo < ActiveRecord::Migration
  def change
    add_column :player_infos, :contact_pref, :string, length: 60
  end
end
