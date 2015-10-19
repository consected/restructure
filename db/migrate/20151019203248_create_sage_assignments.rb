class CreateSageAssignments < ActiveRecord::Migration
  def change
    create_table :sage_assignments do |t|
      t.integer :sage_ext_id
      t.string :assigned_by
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
