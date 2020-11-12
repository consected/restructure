class AddStatusChangedToMessageNotifications < ActiveRecord::Migration
  def change
    add_column :message_notifications, :status_changed, :string
  end
end
