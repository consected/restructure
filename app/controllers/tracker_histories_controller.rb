class TrackerHistoriesController < ApplicationController

  before_action :authenticate_user!
  before_action :set_parent_item
  
  def index
    if @tracker
      logger.info "Getting tracker item tracker histories"
      @tracker_histories = @tracker.tracker_histories.order Master::OutcomeEventDatesNotNullClause
    elsif @master
      logger.info "Getting master tracker histories"
      @tracker_histories = @master.tracker_histories.order Master::OutcomeEventDatesNotNullClause
    else
      render code: 404
      return
    end
    
    logger.info "Tracker histories returned #{@tracker_histories.length} items"
    
    if params[:skip_last]=='true'
      # Remove a current tracker item from the list.
      mid = @tracker_histories.max_by {|x| x.id}      
      @tracker_histories = @tracker_histories.reject {|x| x.id == mid.id}
    end
    
    render json: {results: @tracker_histories, master_id: @master.id}
  end
  
  

  private
  
    def set_parent_item
      if params[:tracker_id].blank?
        @tracker = nil
        @master = Master.find(params[:master_id])
      else
        @tracker = Tracker.find(params[:tracker_id])
        @master = @tracker.master
      end
    end
      
    def secure_params
      params.require(:tracker).permit(:master_id,  :protocol_id, :event, :event_date, :c_method, :outcome, :outcome_date, :user_id, :notes)
    end
end
