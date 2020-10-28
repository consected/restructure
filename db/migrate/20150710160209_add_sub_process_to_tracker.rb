class AddSubProcessToTracker < ActiveRecord::Migration
  def change
    add_reference :trackers, :sub_process, index: true, foreign_key: true
    add_reference :trackers, :protocol_event, index: true, foreign_key: true

  end
end
