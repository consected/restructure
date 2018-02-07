class Admin::UserAuthorizationsController < ApplicationController

  include AdminControllerHandler
  helper_method  :has_access_levels, :user_id_options

  protected

    def filters
      User.active.map {|u| [u.id.to_s, u.email] }.to_h
    end

    def filters_on
      :user_id
    end

    def has_access_levels
      UserAccessControls.access_levels.map {|m| [m.to_s.titleize, m]}
    end

    def user_id_options
      User.active.map {|u| [u.email, u.id]}
    end

    def view_folder
      'admin/common_templates'
    end

    def permitted_params
      @permitted_params = [:id, :access, :resource_type, :resource_name, :options, :user_id]
    end

    def secure_params
      params.require(object_name.to_sym).permit(*permitted_params)
    end


end
