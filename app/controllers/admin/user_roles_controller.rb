class Admin::UserRolesController < AdminController

  before_action :set_help_description
  before_action :setup_copy, only: [:index]

  def copy_user_roles

    from_user_id = params[:from_user_id]
    to_user_id = params[:to_user_id]
    app_type_id = params[:app_type_id]

    from_user = User.active.find from_user_id
    to_user = User.active.find to_user_id
    app_type = Admin::AppType.active.find app_type_id

    res = Admin::UserRole.copy_user_roles from_user, to_user, app_type, current_admin

    flash.now[:notice] = "#{to_user.email} now has #{res.length} roles for app #{app_type.name}"
    index

  end

  def view_folder
    'admin/common_templates'
  end

  def default_index_order
    {app_type_id: :asc, user_id: :asc, role_name: :asc}
  end

  def filters
    res = {
      app_type_id: Admin::AppType.all_by_name,
      role_name: Admin::UserRole.active.role_names.sort,
      user_id: Admin::UserRole.active.users.pluck(:id, :email).to_h
    }
  end

  def filters_on
    [:app_type_id, :role_name, :user_id]
  end


  private
    def permitted_params
      [:app_type_id, :role_name, :user_id, :disabled]
    end

    def setup_copy
      @extra_part = 'admin/user_roles/copy_user_roles'

    end

    def set_help_description
      @help_description = <<EOF
<h4>Role Naming</h4>
<p>Role naming is important when applied to <i>User Access Controls</i>, since the naming sets the priority with which they are applied.</p>
<p>As a rule of thumb, for a general, default role, name the role like <b>user - <i>some function</i></b>, where 'some function' represents the process a user with that role has access to.
Then for higher priority roles, those that will override the default, name something like <b><i>org role</i> - <i>some function</i></b>, where the 'org role' could be something like 'manager'.
<p>For example, a process could have roles defined: <b>user - scheduling</b>, <b>planner - scheduling</b>, <b>approver - scheduling</b>, <b>reviewer - scheduling</b></p>
<p>Any role name that is earlier alphabetically will override those farther down the alphabet, meaning that 'user - ...' is a convenient convention for default users since it will be overridden in most cases.</p>
EOF
      @help_description = @help_description.html_safe
    end

end
