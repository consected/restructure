class Admin::AppConfigurationsController < AdminController

  protected
  def filters
    {
      name: AppConfiguration.configurations,
      app_type_id: AppType.all_by_name
    }
  end

  def filters_on
    [:name, :app_type_id]
  end

    def default_index_order
      {name: :asc}
    end

  private
    def secure_params
        params.require(object_name.to_sym).permit(:name, :value, :app_type_id, :user_id, :disabled)
    end
end
