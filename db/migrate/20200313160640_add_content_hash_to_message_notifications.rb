class AddContentHashToMessageNotifications < ActiveRecord::Migration
  def change
    add_column :message_notifications, :content_hash, :string
  end
end
