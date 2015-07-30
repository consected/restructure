class AddUserToCollege < ActiveRecord::Migration
  def change
    add_reference :colleges, :user, index: true, foreign_key: true
  end
end
