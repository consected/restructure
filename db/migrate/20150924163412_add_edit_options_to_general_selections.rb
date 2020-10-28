class AddEditOptionsToGeneralSelections < ActiveRecord::Migration
  def change
    add_column :general_selections, :create_with, :boolean
    add_column :general_selections, :edit_if_set, :boolean
    add_column :general_selections, :edit_always, :boolean
    add_column :general_selections, :position, :integer
    add_column :general_selections, :description, :string
  end
end
