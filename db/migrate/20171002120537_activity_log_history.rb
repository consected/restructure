class ActivityLogHistory < ActiveRecord::Migration
  def change
    create_table :activity_log_history do |t|
      t.references :activity_log, index: true, foreign_key: true
      t.string :name
      t.string :item_type
      t.string :rec_type
      t.references :admin
      t.boolean :disabled

      t.timestamps null: false
    end    
  end
end
