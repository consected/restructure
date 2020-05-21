# frozen_string_literal: true

class AdminController < ApplicationController
  include AdminControllerHandler
  include FilterUtils
  include AdminActionLogging

  layout 'admin_application'
  helper_method :object_has_admin_parent?, :object_name, :editor_code_type, :filter_params_permitted, :filter_params_hash

  protected

  def object_has_admin_parent?
    object_instance.class.parent.to_s.in? Admin::AdminBase::ValidAdminModules
  end

  def editor_code_type
    'yaml'
  end

  private

  def secure_params
    params.require(object_name.gsub('__', '_').to_sym).permit(*permitted_params)
  end
end
