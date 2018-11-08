class AdminController < ApplicationController
  include AdminControllerHandler
  include FilterUtils
  include AdminActionLogging

  layout 'admin_application'
  helper_method :object_has_admin_parent?, :object_name, :editor_code_type

  protected

   def object_has_admin_parent?
     object_instance.class.parent.in? [Admin, Classification]
   end

   def editor_code_type
     "yaml"
   end

  private

    def secure_params
      params.require(object_name.gsub('__', '_').to_sym).permit(*permitted_params)
    end
end
