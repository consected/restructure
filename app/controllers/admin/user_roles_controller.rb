class Admin::UserRolesController < AdminController

  def view_folder
    'admin/common_templates'
  end

  def filters
    res = {
      app_type_id: Admin::AppType.all_by_name,
      role_name: UserRole.active.role_names,
      user_id: UserRole.active.users.pluck(:id, :email).to_h
    }
  end

  def filters_on
    [:app_type_id, :role_name, :user_id]
  end


  private
    def permitted_params
      [:app_type_id, :role_name, :user_id, :disabled]
    end
end
