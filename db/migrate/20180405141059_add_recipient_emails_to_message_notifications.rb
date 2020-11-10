class AddRecipientEmailsToMessageNotifications < ActiveRecord::Migration
  def change
    add_column :message_notifications, :recipient_emails, :string, array: true
    add_column :message_notifications, :from_user_email, :string
  end
end
