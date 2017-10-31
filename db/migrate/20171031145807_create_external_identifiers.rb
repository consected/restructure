class CreateExternalIdentifiers < ActiveRecord::Migration
  def change
    create_table :external_identifiers do |t|
      t.string :name
      t.string :label
      t.string :external_id_attribute
      t.string :external_id_view_formatter
      t.boolean :prevent_edit
      t.boolean :pregenerate_ids
      t.integer :min_id, limit: 8
      t.integer :max_id, limit: 8
      t.belongs_to :admin, index: true, foreign_key: true
      t.boolean :disabled
      t.timestamps null: false
    end
  end
end
