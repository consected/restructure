class TrackersController < ApplicationController
  include MasterHandler

  def index
    set_objects_instance @master_objects
    s = @master_objects.order Master::OutcomeEventDatesNotNullClause
    render json: {results: s, master_id: @master.id}
  end

  
  private
    
    def secure_params
      params.require(:tracker).permit(:master_id,  :protocol_id, :event, :event_date, :c_method, :outcome, :outcome_date, :user_id, :notes)
    end
end
