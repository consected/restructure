class AddDisabledToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :disabled, :boolean
  end
end
