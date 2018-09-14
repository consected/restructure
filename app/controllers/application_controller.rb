class ApplicationController < ActionController::Base

  include ControllerUtils
  include AppExceptionHandler
  include AppConfigurationsHelper
  include NavHandler
  include UserActionLogging

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :prevent_cache
  before_action :setup_navs

  protected


    def current_email
      return nil unless current_user || current_admin
      (current_user || current_admin).email
    end


    def authenticate_user_or_admin!
      if !current_user && !current_admin
        redirect_to new_user_session_path
      end
      return true
    end

  private

    def no_action_log
      false
    end

end
