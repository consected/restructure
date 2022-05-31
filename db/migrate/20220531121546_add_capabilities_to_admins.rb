class AddCapabilitiesToAdmins < ActiveRecord::Migration[5.2]
  def change
    add_column :admins, :capabilities, :string, array: true
  end
end
