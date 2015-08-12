class AddSourceToPlayerInfo < ActiveRecord::Migration
  def change
    add_column :player_infos, :source, :string
  end
end
