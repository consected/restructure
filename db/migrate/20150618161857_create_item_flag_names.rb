class CreateItemFlagNames < ActiveRecord::Migration
  def change
    create_table :item_flag_names do |t|
      t.string :name
      t.string :item_type
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
