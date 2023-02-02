# frozen_string_literal: true

class AdminController < ApplicationController
  include AdminControllerHandler
  include FilterUtils
  include AdminActionLogging

  layout 'admin_application'
  helper_method :object_has_admin_parent?, :object_name, :editor_code_type,
                :filter_params_permitted, :filter_params_hash, :filter_params

  # Ensure 2FA has been set up if required
  before_action -> { redirect_to '/admins/show_otp' if current_admin.two_factor_setup_required? }

  before_action :check_capabilities!

  protected

  def object_has_admin_parent?
    object_instance.class.name.split('::')[-2].in? Admin::AdminBase::ValidAdminModules
  end

  def editor_code_type
    'yaml'
  end

  private

  def secure_params
    params.require(object_name.gsub('__', '_').to_sym).permit(*permitted_params)
  end

  def check_capabilities!
    return if current_admin.can_admin? controller_name

    raise FphsNotAuthorized,
          "Admin not authorized for #{controller_name}"
  end
end
