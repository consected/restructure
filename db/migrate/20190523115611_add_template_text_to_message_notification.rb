class AddTemplateTextToMessageNotification < ActiveRecord::Migration
  def change
    add_column :message_notifications, :content_template_text, :string
  end
end
