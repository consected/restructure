# frozen_string_literal: true

#
# Provide definitions for User Roles
class Admin::UserRolesController < AdminController
  helper_method :admin_links
  #
  # Handle the request to clear (disable) all user roles for a user in an app type
  def clear_user_roles
    user_id = params[:clear_user_id]
    app_type_id = params[:clear_app_type_id]

    raise FphsException, 'A user must be selected to clear roles' if user_id.blank?
    raise FphsException, 'An app type must be selected to clear roles' if app_type_id.blank?

    user = User.active.find user_id
    app_type = Admin::AppType.active.find app_type_id

    res = Admin::UserRole.clear_user_roles(user, app_type, current_admin)
    resc = res.length
    flash.now[:notice] = "#{user.email} had #{resc} #{'role'.pluralize(resc)} cleared for app #{app_type.name}"
    index
  end

  #
  # Handle the request to copy user roles from one user to another
  def copy_user_roles
    from_user_id = params[:from_user_id]
    to_user_id = params[:to_user_id]
    app_type_id = params[:app_type_id]
    force_not_empty = params[:force_not_empty]
    reenable_disabled = params[:reenable_disabled]

    from_user = User.active.find from_user_id
    to_user = User.active.find to_user_id
    app_type = Admin::AppType.active.find app_type_id

    res = Admin::UserRole.copy_user_roles(from_user, to_user, app_type, current_admin, force_not_empty:,
                                                                                       reenable_disabled:)
    resc = res.length
    flash.now[:notice] = "#{to_user.email} now has #{resc} new #{'role'.pluralize(resc)} for app #{app_type.name}"
    index
  end

  protected

  def view_folder
    'admin/common_templates'
  end

  #
  # Order index results so we can see, for each app, all the roles a user has
  def default_index_order
    { app_type_id: :asc, user_id: :asc, role_name: :asc }
  end

  def filters
    {
      app_type_id: Admin::AppType.all_by_name,
      role_name: Admin::UserRole.active.role_names.sort,
      user_id: Admin::UserRole.active.users.pluck(:id, :email).to_h
    }
  end

  def filters_on
    %i[app_type_id role_name user_id]
  end

  def admin_links(item = nil)
    return [true] if item.nil?

    links = [
      ['description', admin_role_descriptions_path(filter: { role_name: item.role_name })],
      ['user profile', admin_manage_users_path(filter: { id: item.user_id })],
      ['access controls', admin_user_access_controls_path(filter: { role_name: item.role_name })]
    ]

    if item.user_id.present?
      links << [
        'access overview',
        view_context.user_access_overview_report_path(
          :by_role,
          user: item.user_id,
          app_type_id: item.app_type_id,
          role_name: item.role_name
        )
      ]
    end

    if item.role_name.present?
      links << [
        'users with role',
        view_context.user_access_overview_report_path(
          :users_with_role,
          app_type_id: item.app_type_id,
          role_name: item.role_name
        )
      ]
    end

    links
  end

  def index_params
    %i[app_type role_name user admin_id]
  end

  private

  def permitted_params
    %i[app_type_id role_name user_id disabled]
  end

  def show_head_info
    true
  end
end
