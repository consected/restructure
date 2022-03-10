# frozen_string_literal: true

# Regular admins are allowed to create other admin accounts if ALLOW_ADMINS_TO_MANAGE_ADMINS is true.
# Otherwise, the ability to create other admins is limited to an OS-user, using the app-scripts/add_admin.sh command.
#
# Regular admins are always allowed to:
#   1. update other admin's names,
#   2. generate other admin's password or 2FA authorizations
#   3. disable other admins
#
# Re-enabling an admin cannot be done by another admin; this feature remains limited to an OS-user.
class Admin::ManageAdminsController < AdminController
  # Only allow update of the disabled status of an administrator to disabled.
  def update
    if @admin.disabled && secure_params[:disabled] != '1'
      not_authorized
      flash.now[:warning] = 'Admins can not be re-enabled'
      return
    end

    if params[:gen_new_pw] == '1'
      @admin.force_password_reset
      logger.info 'Force password reset'
    end

    @admin.reset_two_factor_auth if params[:reset_two_factor_auth]

    @admin.current_admin = current_admin
    if @admin.update(secure_params)
      @admins = Admin.all
      @updated_with = @admin
      render partial: 'index'
    else
      logger.warn "Error updating #{human_name}: #{object_instance.errors.inspect}"

      edit
    end
  end

  def create
    not_authorized unless Settings::AllowAdminsToManageAdmins

    super
  end

  protected

  def primary_model
    Admin
  end

  def object_name
    @object_name = 'admin'
  end

  def objects_name
    'admins'
  end

  def human_name
    'admin'
  end

  def filters
    {}
  end

  def filters_on
    []
  end

  # Override regular defaults, which force the current admin's app_type_id
  def filter_defaults
    {}
  end

  private

  def permitted_params
    %i[email first_name last_name disabled]
  end
end
