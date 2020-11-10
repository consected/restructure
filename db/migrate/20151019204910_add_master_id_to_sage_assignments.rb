class AddMasterIdToSageAssignments < ActiveRecord::Migration
  def change
    add_reference :sage_assignments, :master, index: true, foreign_key: true
  end
end
