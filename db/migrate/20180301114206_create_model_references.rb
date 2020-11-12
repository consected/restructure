class CreateModelReferences < ActiveRecord::Migration
  def change
    create_table :model_references do |t|
      t.string :from_record_type
      t.integer :from_record_id
      t.references :from_record_master, index: true
      t.string :to_record_type
      t.integer :to_record_id
      t.references :to_record_master, index: true
      t.belongs_to :user, index: true, foreign_key: true
      t.timestamps null: false
    end

    add_index :model_references, [:from_record_type, :from_record_id]
    add_index :model_references, [:to_record_type, :to_record_id]

    add_foreign_key :model_references, :masters, column: :to_record_master_id
    add_foreign_key :model_references, :masters, column: :from_record_master_id

  end
end
