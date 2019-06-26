class IfRoleMissingAdd < ActiveRecord::Migration
  def change

    auto_admin = Admin.active.first

    unless Admin::UserRole.first
      u = User.active.first
      Admin::UserRole.create! role_name: 'zeus', user: u, app_type: u.app_type, current_admin: auto_admin
    end

  end
end
