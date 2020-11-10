class AddAdminToGeneralSelections < ActiveRecord::Migration
  def change
    add_reference :general_selections, :admin, index: true, foreign_key: true
  end
end
