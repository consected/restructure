# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ControllerUtils
  include AppExceptionHandler
  include NfsStore::FsExceptionHandler
  include AppConfigurationsHelper
  include NavHandler
  include UserActionLogging

  # Only allow modern browsers supporting webp images, web push,
  # badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :log_access_for_current_user
  before_action :check_temp_passwords
  before_action :prevent_cache
  before_action :setup_navs
  after_action -> { flash.discard }, if: -> { request.xhr? }

  protected

  def class_parent_name
    self.class.name.split('::')[-2] || 'Object'
  end

  def current_email
    return nil unless current_user || current_admin

    (current_user || current_admin).email
  end

  def authenticate_user_or_admin!
    # Evaluate both helpers (not `!current_user && !current_admin`, which short-circuits and
    # skips current_admin whenever current_user is present) so Devise's Timeoutable hook always
    # refreshes last_request_at for the admin scope too. Admins are typically also signed in as
    # a matching user, so without this the admin session's inactivity timer was never refreshed
    # by requests going through this shared gate, causing it to time out during active use - fixes #1345
    signed_in_user = current_user
    signed_in_admin = current_admin
    redirect_to new_user_session_path unless signed_in_user || signed_in_admin
    true
  end

  def log_access_for_current_user
    current_user.log_access = true if current_user && log_access?
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

  def log_access?
    params[:_log_access] == 'true'
  end

  def no_action_log
    false
  end
end
