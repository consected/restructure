class AdminController < ApplicationController
  include AdminControllerHandler
  include FilterUtils

  helper_method :object_has_admin_parent?, :object_name

  protected

   def object_has_admin_parent?
     object_instance.class.parent == Admin
   end
end
