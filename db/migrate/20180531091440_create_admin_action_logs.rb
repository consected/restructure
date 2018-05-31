class CreateAdminActionLogs < ActiveRecord::Migration
  def change
    create_table :admin_action_logs do |t|
      t.references :admin, index: true, foreign_key: true
      t.string :item_type
      t.integer :item_id
      t.string :action
      t.string :url
      t.json :prev_value
      t.json :new_value
      t.timestamps null: false
    end
  end
end
