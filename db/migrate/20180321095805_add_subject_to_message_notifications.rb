class AddSubjectToMessageNotifications < ActiveRecord::Migration
  def change
    add_column :message_notifications, :subject, :string
  end
end
