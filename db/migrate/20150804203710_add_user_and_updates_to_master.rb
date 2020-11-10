class AddUserAndUpdatesToMaster < ActiveRecord::Migration
  def self.up 
      change_table :masters do |t|
          t.timestamps          
      end
      
    add_reference :masters, :user, index: true, foreign_key: true
  end
  def self.down 
      remove_column :masters, :created_at
      remove_column :masters, :updated_at
      remove_reference :masters, :user, index: true, foreign_key: true
  end
end
