class CreateModelReferences < ActiveRecord::Migration
  def change
    create_table :model_references do |t|
      t.string :from_record_type
      t.integer :from_record_id
      t.string :to_record_type
      t.integer :to_record_id
      t.belongs_to :user, index: true, foreign_key: true
      t.timestamps null: false
    end

    add_index :model_references, [:from_record_type, :from_record_id]
    add_index :model_references, [:to_record_type, :to_record_id]

  end
end
