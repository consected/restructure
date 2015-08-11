class RemoveEventFromTracker < ActiveRecord::Migration
  def change
    remove_column :trackers, :event, :string
    remove_column :tracker_history, :event, :string
  end
end
