class ApplicationController < ActionController::Base

  include ControllerUtils
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_action :setup_navs
  
  
protected

      # Prevent access to any management page unless the user is an administrator
    def check_admin
      redirect_to '/pages' and return unless current_admin
    end

    def setup_navs
      @primary_navs = []
      @secondary_navs = []
      
      if current_user || current_admin
        
        user_sub = []
        user_sub << {label: 'password', url: "/#{current_user ? "users" : current_admin ? "admins" : "exit"}/edit"}
        user_sub << {label: 'logout', url: "/#{current_user ? "users" : current_admin ? "admins" : "exit"}/sign_out", extras: {method: :delete}}
        
        @secondary_navs << {label: '<span class="glyphicon glyphicon-user"></span>', url: "#", sub: user_sub, extras: {title: current_email}}
      end 
      if current_user
        @primary_navs << {label: 'Research', url: '/masters/', route: 'masters#index'}
        @primary_navs << {label: 'Create MSID', url: '/masters/new', route: 'masters#new'}

      end
      
      if current_admin
        @primary_navs << {label: 'Users', url: '/manage_users/', route: 'manage_users#home'}
      end
      
      res  = @primary_navs.select {|n| n[:route] == "#{controller_name}##{action_name}" }            
      res.first[:active] = true if res && res.first

    end
    
    def current_email
      return nil unless current_user || current_admin
      (current_user || current_admin).email
    end
end
