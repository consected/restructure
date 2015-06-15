class AddExtrasToPlayerInfo < ActiveRecord::Migration
  def change
    add_column :player_infos, :start_year, :integer
    add_column :player_infos, :in_survey, :string, limit: 1
    add_column :player_infos, :rank, :integer
    add_column :player_infos, :scantron_id, :integer
    add_column :player_infos, :notes, :string
  end
end
