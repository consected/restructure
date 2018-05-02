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
  before_action :setup_current_app_type

  rescue_from Exception, with: :unhandled_exception_handler
  rescue_from RuntimeError, with: :runtime_error_handler
  rescue_from ActiveRecord::RecordNotFound, with: :runtime_record_not_found_handler
  rescue_from ActionController::RoutingError, with: :routing_error_handler
  rescue_from ActionController::InvalidAuthenticityToken, with: :bad_auth_token
  rescue_from FphsException, with: :fphs_app_exception_handler
  rescue_from PG::RaiseException, with: :fphs_app_exception_handler
  rescue_from ActionDispatch::Cookies::CookieOverflow, with: :cookie_overflow_handler
  rescue_from PG::UniqueViolation, with: :db_unique_violation

protected

    def canceled?
      params[:id] == 'cancel'
    end

    def prevent_cache
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

      # Prevent access to any management page unless the user is an administrator
    def check_admin
      redirect_to '/pages' and return unless current_admin
    end

    def setup_current_app_type
      return unless current_user

      all_apps = Admin::AppType.all_available_to(@current_user)

      # If the current user does not have any app types available, logout and flash a message
      if all_apps.length == 0
        current_user.app_type = nil

        flash[:error] = "You have not been granted access to any application types. Contact an administrator to continue use of the application."
        sign_out current_user
        return
      end

      # If the user requests a change to the app type from the nav bar selector, make the change
      if params[:use_app_type].present?
        a = all_apps.select{|app| app.id == params[:use_app_type].to_i}.first
        if a && current_user.app_type_id != a.id
          current_user.app_type = a
          current_user.save
          # Redirect, to ensure the flash and navs in the layout are updated
          redirect_to masters_search_path
          return
        end
      end

      # If we don't have an app type set, force one
      if current_user.app_type.nil?
        # If there is only one app type, use it
        # Otherwise, assume the first until a user selects otherwise
        current_user.app_type = all_apps.first
        current_user.save
        # Redirect, to ensure the flash and navs in the layout are updated
        redirect_to masters_search_path
        return
      end
    end


    def current_email
      return nil unless current_user || current_admin
      (current_user || current_admin).email
    end

    def not_authorized
      flash[:danger] = "You are not authorized to perform the requested action"
      render text: flash[:danger], status: :unauthorized
    end

    def not_editable
      flash[:danger] = "This item can't be edited"
      render text: flash[:danger], status: :not_editable
    end

    def not_creatable
      flash[:danger] = "This item can't be created"
      render text: flash[:danger], status: 403
    end

    def not_found
      flash[:danger] = "Requested information not found"
      raise ActionController::RoutingError.new('Not Found')
    end

    def bad_request
      flash[:danger] = "The request failed to validate"
      render text: flash[:danger], status: 422
    end

    def unexpected_error msg
      flash[:danger] = "An error occurred: #{msg}"[0..2000]
      render text: flash[:danger], status: 400
    end

    def general_error msg, level=:info
      flash[level] = "Error: #{msg}"[0..2000]
      render text: flash[level], status: 400
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
