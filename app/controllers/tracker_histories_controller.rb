class TrackerHistoriesController < UserBaseController

  before_action :set_parent_item

  def index
    if @tracker
      logger.info "Getting tracker item tracker histories"
      @tracker_histories = @tracker.tracker_histories.order Master::TrackerHistoryEventOrderClause
    elsif @master
      logger.info "Getting master tracker histories"
      @tracker_histories = @master.tracker_histories.order Master::TrackerHistoryEventOrderClause
    else
      render status: 404
      return
    end

    logger.info "Tracker histories returned #{@tracker_histories.length} items"

    if params[:skip_last] == 'true'
      # Remove a current tracker item from the list.
      mid = @tracker_histories.first
      @tracker_histories = @tracker_histories.reject {|x| x.id == mid.id}
    end

    @master_objects = @tracker_histories

    initial_filter_regex = TrackerHistoryFilterConfig.config_for(current_user)
    initial_filter_notes = TrackerHistoryFilterConfig.notes_initial_for(current_user)
    initial_filter_dates = TrackerHistoryFilterConfig.date_initial_for(current_user)

    render json: {
      tracker_histories: @tracker_histories,
      master_id: @master.id,
      initial_filter_regex: initial_filter_regex,
      initial_filter_notes: initial_filter_notes,
      initial_filter_date_from: initial_filter_dates[:date_from],
      initial_filter_date_to: initial_filter_dates[:date_to],
      record_updates_protocol_name: Classification::Protocol::RecordUpdatesProtocolName
    }
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
      params.require(:tracker).permit(:master_id,  :protocol_id, :event, :event_date, :sub_process_id, :outcome, :outcome_date, :user_id, :notes, :item_id, :item_type)
    end
end
