class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.string :name      
      t.string :primary_table
      t.string :description
      t.string :sql
      t.string :search_attrs
      t.references :admin, index: true, foreign_key: true
      t.boolean :disabled
      t.timestamps null: false
    end
  end
end
