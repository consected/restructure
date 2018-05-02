class CreatePageLayouts < ActiveRecord::Migration
  def change
    create_table :page_layouts do |t|
      t.belongs_to :app_type, index: true, foreign_key: true
      t.string :layout_name
      t.string :panel_name
      t.string :panel_label
      t.integer :panel_position
      t.string :options
      t.boolean :disabled
      t.belongs_to :admin, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
