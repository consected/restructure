class AddRoleNameToMessageNotifications < ActiveRecord::Migration
  def change
    add_column :message_notifications, :role_name, :string
  end
end
