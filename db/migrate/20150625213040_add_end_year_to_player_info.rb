class AddEndYearToPlayerInfo < ActiveRecord::Migration
  def change
    add_column :player_infos, :end_year, :integer
  end
end
