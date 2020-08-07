class AddImportanceToMessageNotifications < ActiveRecord::Migration
  def change
    add_column :message_notifications, :importance, :string
  end
end
