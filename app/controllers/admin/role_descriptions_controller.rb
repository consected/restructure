# frozen_string_literal: true

#
# Provide descriptions of user roles (based on role_name) or groups of roles representing
# business roles (based on roles for users with email ending @template)
class Admin::RoleDescriptionsController < AdminController
  helper_method :role_name_options, :role_template_options, :description_editor

  def view_folder
    'admin/common_templates'
  end

  def role_name_options
    Admin::RoleDescription.role_names_by_app_name
  end

  def role_template_options
    Admin::RoleDescription.role_templates
  end

  def description_editor
    :markdown
  end

  def extra_field_attributes
    {
      app_type_id: {
        'data-filters-select': '#admin_role_description_role_name'
      }
    }
  end

  #
  # Order index results so we can see, for each app, all the role names
  def default_index_order
    { app_type_id: :asc, role_name: :asc }
  end

  def filters
    {
      app_type_id: Admin::AppType.all_by_name,
      role_name: Admin::RoleDescription.role_names_by_app_name.transform_keys { |k| k.split('/').last },
      role_template: Admin::RoleDescription.role_templates.transform_keys { |k| k.split('/').last }
    }
  end

  def filters_on
    %i[app_type_id role_name role_template]
  end

  private

  def permitted_params
    %i[app_type_id role_name role_template name description disabled]
  end
end
