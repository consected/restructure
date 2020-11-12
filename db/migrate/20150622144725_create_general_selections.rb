class CreateGeneralSelections < ActiveRecord::Migration
  def change
    create_table :general_selections do |t|
      t.string :name
      t.string :value
      t.string :item_type

      t.timestamps null: false
    end
  end
end
