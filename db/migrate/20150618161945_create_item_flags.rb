class CreateItemFlags < ActiveRecord::Migration
  def change
    create_table :item_flags do |t|
      t.integer :item_id
      t.string :item_type
      t.references :item_flag_name, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
