class AddTimestampsToCollege < ActiveRecord::Migration
  def self.up 
        change_table :colleges do |t|
            t.timestamps
        end
    end
    def self.down 
        remove_column :colleges, :created_at
        remove_column :colleges, :updated_at
    end
end
