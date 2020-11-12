class AddNotesToTracker < ActiveRecord::Migration
  def change
    add_column :trackers, :notes, :string
  end
end
