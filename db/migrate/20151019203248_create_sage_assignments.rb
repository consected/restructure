class CreateSageAssignments < ActiveRecord::Migration
  def change
    create_table :sage_assignments do |t|
      t.string :sage_id, limit: 10      
      t.string :assigned_by
      t.references :user, index: true, foreign_key: true      
      t.timestamps null: false
    end
    
    add_index :sage_assignments, :sage_id, unique: true
  end
end
