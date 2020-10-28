class CreateSubProcesses < ActiveRecord::Migration
  def change
    create_table :sub_processes do |t|
      t.string :name
      t.boolean :disabled
      t.belongs_to :protocol, index: true, foreign_key: true
      t.references :admin, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
