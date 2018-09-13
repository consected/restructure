class AddRoleNameToAppConfiguration < ActiveRecord::Migration
  def change
    add_column :app_configurations, :role_name, :string
  end
end
