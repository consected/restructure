# frozen_string_literal: true

class Admin::ManageUsersController < AdminController
  def update
    if params[:gen_new_pw] == '1'
      @user.force_password_reset
      logger.warn 'Force password reset'
    end

    if params[:reset_two_factor_auth]
      @user.reset_two_factor_auth
      logger.warn 'Force 2FA reset'
    end

    if params[:extend_expiration]
      @user.extend_expiration
      logger.warn 'Extend user password expiration'
    end

    if params[:unlock_failed_attempts]
      @user.unlock_failed_attempts
      logger.warn 'Unlock user password failed attempts'
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

  def title
    'Usernames and Passwords'
  end

  def filters
    {
      app_type_id: Admin::AppType.all_by_name
    }
  end

  def filters_on
    [:app_type_id]
  end

  # Override regular defaults, which force the current user's app_type_id
  def filter_defaults
    {}
  end

  # Run a special filter on app_type_id, so that we don't just get the
  # users current app, but all they have access to
  def filtered_primary_model(_ = nil)
    pm = primary_model
    a = filter_params_permitted[:app_type_id] if filter_params_permitted
    if a.present?
      # A filter was selected. Limit the results to just users that can access the specified app.
      a = a.to_i
      # Set the app_type_id param to nil, so the super method doesn't attempt to filter on it
      filter_params_permitted[:app_type_id] = nil
      ids = pm.all.select { |u| a.in?(u.accessible_app_type_ids) }.map(&:id)
      pm = pm.where(id: ids)
    end

    # Filter on everything (except the specified app_type_id, which has beem temporarily removed)
    res = super(pm)

    # Reset the filter params so that the buttons appear correctly
    filter_params_permitted[:app_type_id] = a.to_s if a.present?
    res
  end

  private

  def permitted_params
    %i[email disabled first_name last_name do_not_email]
  end
end
