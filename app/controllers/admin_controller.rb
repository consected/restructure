# frozen_string_literal: true

class AdminController < ApplicationController
  include AdminControllerHandler
  include FilterUtils
  include AdminActionLogging

  layout 'admin_application'
  helper_method :object_has_admin_parent?, :object_name, :editor_code_type,
                :filter_params_permitted, :filter_params_hash, :filter_params,
                :perform_action, :perform_action_init_params, :non_column_filter_keys

  # Ensure 2FA has been set up if required
  before_action -> { redirect_to '/admins/show_otp' if current_admin.two_factor_setup_required? }

  before_action :check_capabilities!
  after_action -> { flash.discard }, if: -> { request.xhr? }

  protected

  def object_has_admin_parent?
    object_instance.class.name.split('::')[-2].in? Admin::AdminBase::ValidAdminModules
  end

  def editor_code_type
    'yaml'
  end

  # The capability used to determine if an admin can administer a particular admin controller
  # Typically this is just the controller name, but it can be overridden,
  # for example to group controllers into specific capabilities (such as "redcap")
  def capability_name
    controller_name
  end

  def perform_action
    pa = params[:perform_action]
    return unless pa.in?(%w[new edit])

    @perform_action ||= pa
  end

  def perform_action_init_params
    iw = params[:init_with]
    return unless iw

    # convert hash into url params
    sp = params.require(:init_with).permit(*permitted_params)
    sp.to_query('init_with')
  end

  private

  def secure_params
    params.require(object_name.gsub('__', '_').to_sym).permit(*permitted_params)
  end

  #
  # Check the admin can administer this controller
  def check_capabilities!
    return if current_admin.can_admin? capability_name

    raise FphsNotAuthorized,
          "Admin not authorized for #{capability_name}"
  end
end
