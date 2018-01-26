class Admin::AppConfigurationsController < ApplicationController
  include AdminControllerHandler


  private
    def secure_params
        params.require(object_name.to_sym).permit(:name, :value, :user_id, :disabled)
    end
end
