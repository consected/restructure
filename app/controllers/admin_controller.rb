class AdminController < ApplicationController
  include AdminControllerHandler

  private

    def secure_params
      params.require(object_name.to_sym).permit(*permitted_params)
    end
end
