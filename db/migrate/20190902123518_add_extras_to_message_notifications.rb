class AddExtrasToMessageNotifications < ActiveRecord::Migration
  def change
    add_column :message_notifications, :extra_substitutions, :string    
  end
end
