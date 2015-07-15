class AddPositionToTracker < ActiveRecord::Migration
  def change
    add_column :protocols, :position, :integer
    add_column :protocol_events, :milestone, :string
    add_column :protocol_events, :description, :string
    add_column :tracker_history, :item_id, :integer 
    add_column :trackers, :item_id, :integer 
    add_column :tracker_history, :item_type, :string
    add_column :trackers, :item_type, :string
  end
end
