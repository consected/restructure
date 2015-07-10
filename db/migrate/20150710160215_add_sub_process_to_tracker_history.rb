class AddSubProcessToTrackerHistory < ActiveRecord::Migration
  def change
    add_reference :tracker_history, :sub_process, index: true, foreign_key: true
    add_reference :tracker_history, :protocol_event, index: true, foreign_key: true
  end
end
