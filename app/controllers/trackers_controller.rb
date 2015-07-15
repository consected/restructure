class TrackersController < ApplicationController
  include MasterHandler

  before_action :merge_if_exists, only: [:create]
  
  def index
    set_objects_instance @master_objects
    s = @master_objects #.includes(:protocol).order Master::TrackerEventOrderClause
    render json: {results: s, master_id: @master.id}
  end

    
  private
  
    def merge_if_exists
      @tracker = @master_objects.build(secure_params)

      res = @tracker.merge_if_exists

      if res
        @tracker = res
        show
        return false
      end
    end

    def secure_params
      params.require(:tracker).permit(:master_id,  :protocol_id, :protocol_event_id, :event_date, :sub_process_id, :outcome, :outcome_date, :user_id, :notes, :item_id, :item_type)
    end
end
