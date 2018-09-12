class Admin::AppConfigurationsController < AdminController

  protected
  def filters
    {
      name: Admin::AppConfiguration.configurations,
      app_type_id: Admin::AppType.all_by_name
    }
  end

  def filters_on
    [:name, :app_type_id]
  end

    def default_index_order
      {name: :asc}
    end

  private
    def permitted_params
        [:name, :value, :app_type_id, :role_name, :user_id, :disabled]
    end
end
