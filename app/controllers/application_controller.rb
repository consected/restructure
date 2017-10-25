class ApplicationController < ActionController::Base

  include ControllerUtils
  include AppExceptionHandler

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :prevent_cache
  before_action :setup_navs

  rescue_from Exception, :with => :unhandled_exception_handler
  rescue_from RuntimeError, :with => :runtime_error_handler
  rescue_from ActiveRecord::RecordNotFound, :with => :runtime_record_not_found_handler
  rescue_from ActionController::RoutingError, :with => :routing_error_handler
  rescue_from ActionController::InvalidAuthenticityToken, :with => :bad_auth_token
  rescue_from FphsException, :with => :fphs_app_exception_handler
  rescue_from PG::RaiseException, :with => :fphs_app_exception_handler


protected


    def prevent_cache
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

      # Prevent access to any management page unless the user is an administrator
    def check_admin
      redirect_to '/pages' and return unless current_admin
    end

    def setup_navs

      return true if request.xhr?

      @primary_navs = []
      @secondary_navs = []

      admin_sub = []
      if current_admin

        admin_sub << {label: 'manage', url: '/', route: '#root'}

        admin_sub << {label: 'password', url: "/admins/edit", extras: {'data-do-action' => 'admin-change-password'}}
        admin_sub << {label: 'logout_admin', url: "/admins/sign_out", extras: {method: :delete, 'data-do-action' => 'admin-logout'}}

      else
        admin_sub << {label: 'Admin Login', url: '/admins/sign_in', route: 'admins#sign_in', }
      end

      if current_user
        user_sub = []
        user_sub << {label: 'password', url: "/users/edit", extras: {'data-do-action' => 'user-change-password'}}
        user_sub << {label: 'logout', url: "/users/sign_out", extras: {method: :delete, 'data-do-action' => 'user-logout'}}
      end
      if current_user  || current_admin
        @secondary_navs << {label: '<span class="glyphicon glyphicon-wrench" title="administrator"></span>', url: "#", sub: admin_sub, extras: {'data-do-action' => 'show-admin-options'}}
        @secondary_navs << {label: '<span class="glyphicon glyphicon-user" title="user"></span>', url: "#", sub: user_sub, extras: {title: current_email, 'data-do-action' => 'show-user-options'}}
      end


      if current_user
        @primary_navs << {label: 'Research', url: '/masters/', route: 'masters#index'}
        @primary_navs << {label: 'Create MSID', url: '/masters/new', route: 'masters#new'}  if current_user.can? :create_msid
      end

      if current_user || current_admin
        @primary_navs << {label: 'Reports', url: '/reports', route: 'reports#index'} if current_admin || current_user.can?(:view_reports)
        @primary_navs << {label: 'Import CSV', url: '/imports', route: 'imports#index'}  if current_admin || current_user.can?(:import_csv)

      end

      res  = @primary_navs.select {|n| n[:route] == "#{controller_name}##{action_name}" }
      res.first[:active] = true if res && res.first

    end

    def current_email
      return nil unless current_user || current_admin
      (current_user || current_admin).email
    end

    def not_authorized
      flash[:danger] = "You are not authorized to perform the requested action"
      render text: flash[:danger], status: :unauthorized
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
      flash[:danger] = "An error occurred: #{msg}"
      render text: flash[:danger], status: 400
    end

    def general_error msg, level=:info
      flash[level] = "Error: #{msg}"
      render text: flash[level], status: 400
    end

    def authenticate_user_or_admin!
      if !current_user && !current_admin
        redirect_to new_user_session_path
      end
      return true
    end

end
