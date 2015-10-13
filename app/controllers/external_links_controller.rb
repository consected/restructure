class ExternalLinksController < ApplicationController
  include AdminControllerHandler

  private
    def secure_params
      params.require(:external_link).permit(:name, :value, :disabled)
    end
end
