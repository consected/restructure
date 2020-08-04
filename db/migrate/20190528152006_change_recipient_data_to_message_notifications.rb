class ChangeRecipientDataToMessageNotifications < ActiveRecord::Migration[4.2]
  def change
    rename_column :message_notifications, :recipient_emails, :recipient_data
  end
end
