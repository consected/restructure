class ActivityLogs < ActiveRecord::Migration
  def change
    create_table :activity_logs do |t|
      t.integer :item_id
      t.string :item_type
      
      t.timestamps null: false
    end
  end
end
