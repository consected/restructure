class RemoveRankFromProInfo < ActiveRecord::Migration
  def change
    remove_column :pro_infos, :rank, :string
  end
end
