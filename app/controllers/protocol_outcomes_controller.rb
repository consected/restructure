class ProtocolOutcomesController < ApplicationController
  include AdminControllerHandler


  private
    def secure_params
      params.require(:protocol_outcome).permit(:name, :protocol_id, :disabled)
    end
end
