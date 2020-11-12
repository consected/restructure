class AddEmailToPlayerInfo < ActiveRecord::Migration
  def change
    add_column :player_infos, :current_email, :string
  end
end
