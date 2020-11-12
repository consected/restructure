class AddPasswordCreatedToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :password_updated_at, :datetime
  end
end
