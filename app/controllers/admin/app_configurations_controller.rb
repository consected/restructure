class Admin::AppConfigurationsController < ApplicationController
  include AdminControllerHandler

  protected
    def filters
      AppType.active.map {|g| [g.id.to_s, g.name]}.to_h
    end

    def filters_on
      :app_type
    end

    def default_index_order
      {name: :asc}
    end

  private
    def secure_params
        params.require(object_name.to_sym).permit(:name, :value, :app_type_id, :user_id, :disabled)
    end
end
