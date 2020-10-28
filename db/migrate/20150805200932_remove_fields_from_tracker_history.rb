class RemoveFieldsFromTrackerHistory < ActiveRecord::Migration
  def change
    remove_column :tracker_history, :c_method, :string
    remove_column :tracker_history, :outcome, :string
    remove_column :tracker_history, :outcome_date, :datetime
    
    
  end
end
