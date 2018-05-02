class Admin::UserAccessControlsController < AdminController

  helper_method  :has_access_levels, :user_id_options

  protected

    def filters
      {
        resource_name: Admin::UserAccessControl.resource_names_by_type,
        app_type_id: Admin::AppType.all_by_name,
        user_id: User.active.pluck(:id, :email).to_h
      }
    end

    def filters_on
      [:resource_name, :app_type_id, :user_id]
    end

    def has_access_levels
      UserAccessControls.access_levels.map {|m| [m.to_s.titleize, m]}
    end

    def user_id_options
      User.active.map {|u| [u.email, u.id]}
    end


    def permitted_params
      @permitted_params = [:id, :access, :resource_type, :resource_name, :options, :app_type_id, :user_id, :disabled]
    end

end
