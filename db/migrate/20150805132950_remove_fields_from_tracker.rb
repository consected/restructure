class RemoveFieldsFromTracker < ActiveRecord::Migration
  def change
    remove_column :trackers, :c_method, :string
    remove_column :trackers, :outcome, :string
    remove_column :trackers, :outcome_date, :datetime
    
    
  end
end
