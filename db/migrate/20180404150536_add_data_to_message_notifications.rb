class AddDataToMessageNotifications < ActiveRecord::Migration
  def change
    add_column :message_notifications, :data, :json
  end
end
