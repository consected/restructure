class CreateExternalLinks < ActiveRecord::Migration
  def change
    create_table :external_links do |t|
      t.string :name
      t.string :value
      t.boolean :disabled
      t.references :admin, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
