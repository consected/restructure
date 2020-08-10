# Migration version added
class AddImportanceToMessageNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :message_notifications, :importance, :string
  end
end
