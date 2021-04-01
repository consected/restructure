class CreateImportsModelGenerators < ActiveRecord::Migration[5.2]
  def change
    create_table :imports_model_generators do |t|
      t.string :name
      t.string :dynamic_model_table
      t.json :options
      t.string :description
      t.belongs_to :admin, foreign_key: true
      t.timestamps null: false
    end
  end
end
