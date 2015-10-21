class CreateDynamicModels < ActiveRecord::Migration
  def change
    create_table :dynamic_models do |t|
      t.string :name
      t.string :table_name
      t.string :schema_name
      t.string :primary_key_name
      t.string :foreign_key_name
      t.string :description
      t.references :admin, index: true, foreign_key: true
      t.boolean :disabled

      t.timestamps null: false
    end
  end
end
