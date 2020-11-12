class AddDisabledToGeneralSelections < ActiveRecord::Migration
  def change
    add_column :general_selections, :disabled, :boolean
  end
end
