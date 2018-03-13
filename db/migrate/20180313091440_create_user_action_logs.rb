class CreateUserActionLogs < ActiveRecord::Migration
  def change
    create_table :user_action_logs do |t|
      t.references :user, index: true, foreign_key: true
      t.references :app_type, index: true, foreign_key: true
      t.references :master, index: true, foreign_key: true
      t.string :item_type
      t.integer :item_id
      t.integer :index_action_ids, array: true
      t.string :action

      t.timestamps null: false
    end
  end
end
