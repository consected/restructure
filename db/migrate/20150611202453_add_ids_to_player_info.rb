class AddIdsToPlayerInfo < ActiveRecord::Migration
  def change
    add_column :player_infos, :contact_id, :integer
    add_reference :player_infos, :pro_info, index: true, foreign_key: true
  end
end
