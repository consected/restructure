class AddRoleNameToUserAccessControls < ActiveRecord::Migration
  def change
    add_column :user_access_controls, :role_name, :string, default: nil
  end
end
