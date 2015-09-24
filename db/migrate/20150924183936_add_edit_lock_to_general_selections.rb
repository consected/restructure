class AddEditLockToGeneralSelections < ActiveRecord::Migration
  def change
    add_column :general_selections, :lock, :boolean
  end
end
