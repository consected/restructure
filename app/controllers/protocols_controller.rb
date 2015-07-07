class ProtocolsController < ApplicationController
  include AdminControllerHandler


  private
    def secure_params
      params.require(:protocol).permit(:name, :disabled)
    end
end
