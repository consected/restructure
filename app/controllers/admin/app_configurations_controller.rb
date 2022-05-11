class Admin::AppConfigurationsController < AdminController
  helper_method :role_name_options, :value_editor

  protected

  def filters
    {
      name: Admin::AppConfiguration.configurations,
      app_type_id: Admin::AppType.all_by_name
    }
  end

  def filters_on
    %i[name app_type_id]
  end

  def default_index_order
    { name: :asc }
  end

  def role_name_options
    Admin::UserRole.active.role_names_by_app_name
  end

  def extra_field_attributes
    {
      app_type_id: {
        'data-filters-select': '#admin_app_configuration_role_name'
      }
    }
  end

  def value_editor
    :plain_text
  end

  private

  def permitted_params
    %i[app_type_id role_name user_id name value disabled]
  end
end
