class Admin::UserAccessControlsController < AdminController

  helper_method  :has_access_levels, :user_id_options

  protected

    def filters
      UserAccessControl.resource_names_by_type
    end

    def filters_on
      :resource_name
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

    def secure_params
      params.require(object_name.to_sym).permit(*permitted_params)
    end


end
