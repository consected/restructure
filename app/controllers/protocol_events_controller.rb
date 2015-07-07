class ProtocolEventsController < ApplicationController
  include AdminControllerHandler


  private
    def secure_params
      params.require(:protocol_event).permit(:name, :protocol_id, :disabled)
    end
end
