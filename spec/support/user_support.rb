module UserSupport

  def enable_user_app_access app_name, user=nil
    @user.app_type = Admin::AppType.where(name: app_name).first
    setup_access :app_type, resource_type: :general, access: :read, user: user
  end

  def setup_access resource_name=nil, resource_type: :table, access: :create, user: nil

    return if @path_prefix == "/admin"
    resource_name ||= objects_symbol

    uac = Admin::UserAccessControl.where(app_type: @user.app_type, resource_type: resource_type, resource_name: resource_name)
    uac = uac.where(user: user) if user

    if uac.active.length > 1
      uac.active.update_all(disabled: true)
    end
    uac = uac.active.first || uac.first
    if uac
      uac.access = access
      uac.disabled = false
      uac.current_admin = auto_admin
      uac.save!
    else
      Admin::UserAccessControl.create! app_type: @user.app_type, access: access, resource_type: resource_type, resource_name: resource_name, user: user, current_admin: auto_admin
    end

  rescue => e
    Rails.logger.debug "Failed to create access for #{resource_name}"
  end

  def add_user_to_role role_name, for_user: nil
    for_user ||= @user
    Admin::UserRole.add_to_role for_user, for_user.app_type, role_name, @admin
  end

  def remove_user_from_role role_name, for_user: nil
    for_user ||= @user
    Admin::UserRole.remove_from_role for_user, for_user.app_type, role_name, @admin
  end

  def add_user_config config_name, config_value, for_user: nil
    for_user ||= @user
    Admin::AppConfiguration.add_user_config for_user, for_user.app_type, config_name, config_value, @admin
  end


  def remove_user_config config_name, for_user: nil
    for_user ||= @user
    Admin::AppConfiguration.remove_user_config for_user, for_user.app_type, config_name, @admin
  end


end
