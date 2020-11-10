class RemoveRankFromScantron < ActiveRecord::Migration
  def change
    remove_column :scantrons, :rank, :string
  end
end
