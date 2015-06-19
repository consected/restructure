class TrackersController < ApplicationController
  include MasterHandler
  
  private
    
    def secure_params
      params.require(:tracker).permit(:master_id,  :protocol_id, :event, :event_date, :c_method, :outcome, :outcome_date, :user_id, :notes)
    end
end
