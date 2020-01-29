class Admin::ManageUsersController < AdminController


  def update
    if params[:gen_new_pw] == "1"
      @user.force_password_reset
      logger.info "Force password reset"

      flash[:info] = "New password #{@user.new_password}"
    end

    if params[:reset_two_factor_auth]
      @user.reset_two_factor_auth
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

    def filters
      res = {
        app_type_id: Admin::AppType.all_by_name
      }
    end

    def filters_on
      [:app_type_id]
    end

    # Run a special filter on app_type_id, so that we don't just get the
    # users current app, but all they have access to
    def filtered_primary_model pm=nil

      pm = primary_model
      a = params[:filter][:app_type_id] if params[:filter]
      if a.present?
        a = a.to_i
        params[:filter].delete :app_type_id
        ids = pm.all.select{|u| a.in?(u.accessible_app_types.map(&:id))}.map(&:id)

        pm = pm.where(id: ids)
      end

      super(pm)
    end

  private

    def permitted_params
      [:email, :disabled, :first_name, :last_name, :do_not_email]
    end
end
