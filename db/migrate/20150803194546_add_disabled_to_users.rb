class AddDisabledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :disabled, :boolean
    add_reference :users, :admin, index: true, foreign_key: true
  end
end
