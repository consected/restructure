class Admin::AppTypesController < ApplicationController
  include AdminControllerHandler

  private
    def secure_params
        params.require(object_name.to_sym).permit(:name, :label, :disabled)
    end
end
