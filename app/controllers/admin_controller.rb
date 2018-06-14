class AdminController < ApplicationController
  include AdminControllerHandler
  include FilterUtils
  include AdminActionLogging

  helper_method :object_has_admin_parent?, :object_name

  protected

   def object_has_admin_parent?
     object_instance.class.parent.in? [Admin, Classification]
   end

  private

    def secure_params
      params.require(object_name.gsub('__', '_').to_sym).permit(*permitted_params)
    end
end
