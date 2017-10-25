class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.string :primary_table
      t.integer :item_count
      t.string :filename
      t.integer :imported_items, array: true
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
