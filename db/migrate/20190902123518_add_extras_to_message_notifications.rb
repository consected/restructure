class AddExtrasToMessageNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :message_notifications, :extra_substitutions, :string
  end
end
