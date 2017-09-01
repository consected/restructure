class ActivityLogs < ActiveRecord::Migration
  def change
    create_table :activity_logs do |t|
      t.string :name
      t.string :item_type
      t.string :rec_type
      t.references :admin
      t.boolean :disabled

      t.timestamps null: false
    end
  end
end
