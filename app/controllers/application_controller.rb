class ApplicationController < ActionController::Base

  include ControllerUtils
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
  
  
protected

    def unhandled_exception_handler e
      logger.error e.inspect 
      logger.error e.backtrace.join("\n") 
      respond_to do |type|        
        type.html { render :text => "A unexpected error occurred. Contact the administrator if this condition persists. #{e.message}", :status => 500 }
        type.json  { render :json => {message: "A unexpected error occurred. Contact the administrator if this condition persists. #{e.message}"}, :status => 500 }
      end
      true
    end
      
    def fphs_app_exception_handler e
      logger.error e.inspect 
      logger.error e.backtrace.join("\n") 
      respond_to do |type|        
        type.html { render :text => "#{e.message}", :status => 400 }
        type.json  { render :json => {message: "#{e.message}"}, :status => 500 }        
      end
      true
    end

    def runtime_error_handler e
      logger.error e.inspect 
      logger.error e.backtrace.join("\n") 
      respond_to do |type|
        type.html { render :text => "A server error occurred. Contact the administrator if this condition persists. #{e.message}", :status => 500 }
        type.json  { render :json => {message: "A server error occurred. Contact the administrator if this condition persists."}, :status => 500 }
      end
      true
    end
    
    def routing_error_handler  e
      logger.error e.inspect 
      logger.error e.backtrace.join("\n") 
      respond_to do |type|
        type.html { render :text => "The request URL does not exist.", :status => 404 }
        type.json  { render :json => {message: "The request URL does not exist."}, :status => 404 }
      end
      true
    end
    
    def bad_auth_token e
      logger.error e.inspect 
      logger.error e.backtrace.join("\n") 
      respond_to do |type|
        type.html { render :text => "The information could not be submitted. Try returning to the home page to refresh the page.", :status => 401 }
        type.json  { render :json => {message: "The information could not be submitted. Try returning to the home page to refresh the page."}, :status => 401 }
      end
      true
    end
    
    def runtime_record_not_found_handler e
      logger.error e.inspect 
      logger.error e.backtrace.join("\n") 
      respond_to do |type|
        type.html { render :text => "A database record was not found. Contact the administrator if this condition persists. #{e.message}", :status => 404 }
        type.json  { render :json => {message: "A database record was not found. Contact the administrator if this condition persists."}, :status => 404 }
      end
      true
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

    def setup_navs
      @primary_navs = []
      @secondary_navs = []
      
      admin_sub = []
      if current_admin
        
        admin_sub << {label: 'manage', url: '/', route: '#root'}
        
        admin_sub << {label: 'password', url: "/admins/edit"}
        admin_sub << {label: 'logout_admin', url: "/admins/sign_out", extras: {method: :delete}}
        
      else
        admin_sub << {label: 'Admin Login', url: '/admins/sign_in', route: 'admins#sign_in', }
      end
      
      if current_user 
        user_sub = []
        user_sub << {label: 'password', url: "/users/edit"}
        user_sub << {label: 'logout', url: "/users/sign_out", extras: {method: :delete}}
      end
      if current_user  || current_admin
        @secondary_navs << {label: '<span class="glyphicon glyphicon-wrench" title="administrator"></span>', url: "#", sub: admin_sub, extras: {}}
        @secondary_navs << {label: '<span class="glyphicon glyphicon-user" ></span>', url: "#", sub: user_sub, extras: {title: current_email}}
      end 
      
      
      if current_user
        @primary_navs << {label: 'Research', url: '/masters/', route: 'masters#index'}
        @primary_navs << {label: 'Create MSID', url: '/masters/new', route: 'masters#new'}  if current_user.can? :create_msid        
        
      end
      
      if current_user || current_admin
        @primary_navs << {label: 'Reports', url: '/reports', route: 'reports#index'} if current_admin || current_user.can?(:view_reports)
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
