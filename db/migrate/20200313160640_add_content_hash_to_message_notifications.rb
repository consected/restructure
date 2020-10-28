# Migration version added
class AddContentHashToMessageNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :message_notifications, :content_hash, :string
  end
end
