class Admin::UserAccessControlsController < AdminController

  helper_method  :has_access_levels, :user_id_options

  protected

    def default_index_order
      "app_type_id asc, resource_type asc, translate(resource_name, '__', 'ZZZZ') asc, #{Admin::UserAccessControl::PermissionPriorityOrder}"
    end

    def filters
      {
        app_type_id: Admin::AppType.all_by_name,
        resource_name: Admin::UserAccessControl.resource_names_by_type,
        user_id: User.active.pluck(:id, :email).to_h
      }
    end

    def filters_on
      [:app_type_id, :resource_name, :user_id]
    end

    def has_access_levels
      UserAccessControls.access_levels.map {|m| [m.to_s.titleize, m]}
    end

    def user_id_options
      User.active.map {|u| [u.email, u.id]}
    end


    def permitted_params
      @permitted_params = [:id, :access, :resource_type, :resource_name, :options, :app_type_id, :user_id, :role_name, :disabled]
    end

end
