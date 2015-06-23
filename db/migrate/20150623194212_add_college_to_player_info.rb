class AddCollegeToPlayerInfo < ActiveRecord::Migration
  def change
    add_column :player_infos, :college, :string
  end
end
