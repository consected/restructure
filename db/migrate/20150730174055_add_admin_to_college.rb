class AddAdminToCollege < ActiveRecord::Migration
  def change
    add_reference :colleges, :admin, index: true, foreign_key: true
  end
end
