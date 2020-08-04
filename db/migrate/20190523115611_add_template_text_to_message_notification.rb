class AddTemplateTextToMessageNotification < ActiveRecord::Migration[4.2]
  def change
    add_column :message_notifications, :content_template_text, :string
  end
end
