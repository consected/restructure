class ChangeRecipientDataToMessageNotifications < ActiveRecord::Migration
  def change
    rename_column :message_notifications, :recipient_emails, :recipient_data
  end
end
