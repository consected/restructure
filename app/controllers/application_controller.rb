# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ControllerUtils
  include AppExceptionHandler
  include NfsStore::FsExceptionHandler
  include AppConfigurationsHelper
  include NavHandler
  include UserActionLogging

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :check_temp_passwords
  before_action :prevent_cache
  before_action :setup_navs

  protected

  def class_parent_name
    self.class.name.split('::')[-2] || 'Object'
  end

  def current_email
    return nil unless current_user || current_admin

    (current_user || current_admin).email
  end

  def authenticate_user_or_admin!
    redirect_to new_user_session_path if !current_user && !current_admin
    true
  end

  # If either user or admin has a temp password, force them to change it
  def check_temp_passwords
    return true if request.xhr?

    return true if defined?(ignore_temp_password_for) && ignore_temp_password_for.include?(action_name)

    return true if controller_name.in?(['registrations', 'sessions'])

    if current_user&.has_temp_password?
      redirect_to edit_user_registration_path
    elsif current_admin&.has_temp_password?
      redirect_to edit_admin_registration_path
    end

    true
  end

  private

  def no_action_log
    false
  end
end
