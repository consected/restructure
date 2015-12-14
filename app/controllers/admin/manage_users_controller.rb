class Admin::ManageUsersController < ApplicationController

  include AdminControllerHandler
  #before_action :before_update, only: [:update]    


  def update
    if params[:gen_new_pw] == "1"      
      @user.force_password_reset 
      logger.info "Force password reset"
      
      flash[:info] = "New password #{@user.new_password}"
    end
   
    @user.current_admin = current_admin
    if @user.update(secure_params)
      @users = User.all
      @updated_with = @user
      render partial: 'index'
    else
      logger.warn "Error updating #{human_name}: #{object_instance.errors.inspect}"      
      flash.now[:warning] = "Error updating #{human_name}: #{error_message}"
      edit
    end    
  end
  
  def create
  
    set_object_instance primary_model.new(secure_params)
    object_instance.current_admin = current_admin
    if object_instance.save
      @users = User.all
      @updated_with = @user
      render partial: 'index'
    else
      logger.warn "Error creating #{human_name}: #{object_instance.errors.inspect}"
      flash.now[:warning] = "Error creating #{human_name}: #{error_message}"
      new use_current_object: true
    end
  end  
  
  protected
    
    def primary_model 
      User  
    end
    def object_name 
      @object_name = 'user'
    end
    def objects_name 
      'users'
    end
    def human_name 
      'user'
    end  

  private
  
    def secure_params

      params.require(:user).permit(:email, :disabled)
    end
end
