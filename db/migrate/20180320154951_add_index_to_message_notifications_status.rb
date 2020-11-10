class AddIndexToMessageNotificationsStatus < ActiveRecord::Migration
  def change
    add_index "message_notifications", ["status"], name: "index_message_notifications_status", using: :btree
  end
end
