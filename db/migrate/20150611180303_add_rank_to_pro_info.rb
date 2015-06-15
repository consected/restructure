class AddRankToProInfo < ActiveRecord::Migration
  def change
    add_column :pro_infos, :rank, :integer
  end
end
