# frozen_string_literal: true

# Manage Admins from the admin panel is limited disabling admin accounts. There is no
# ability for regular admins to create or update other admin accounts. This remains
# limited to an OS user, using the app-scripts/add_admin.sh command.
class Admin::ManageAdminsController < AdminController
  # Only allow update of the disabled status of an administrator to disabled.
  def update
    if secure_params[:disabled] != '1'
      not_authorized
      flash.now[:warning] = 'Only allowed to disable existing admins'
      return
    end

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
    not_authorized
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
    %i[disabled]
  end
end
