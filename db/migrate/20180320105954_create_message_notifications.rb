class CreateMessageNotifications < ActiveRecord::Migration
  def change
    create_table :message_notifications do |t|
      t.references :app_type, index: true, foreign_key: true
      t.references :master, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.integer :item_id
      t.string :item_type
      t.string :message_type
      t.integer :recipient_user_ids, array: true
      t.string :layout_template_name
      t.string :content_template_name
      t.string :generated_content
      t.string :status

      t.timestamps null: false
    end
  end
end
