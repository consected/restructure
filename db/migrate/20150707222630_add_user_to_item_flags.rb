class AddUserToItemFlags < ActiveRecord::Migration
  def change
    add_reference :item_flags, :user, index: true, foreign_key: true
  end
end
