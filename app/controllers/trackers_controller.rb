class TrackersController < ApplicationController
  include MasterHandler

  before_action :set_tracker, only: [:show]

  def index
    
    @trackers = @master.trackers
    t = @trackers.as_json(methods: :protocol_name)
    logger.info "Tracker: #{t.to_json}"
    render json: t
  end

  def show
    a = {tracker: @tracker.as_json}
    
    
    logger.info a.as_json
    render json: a
  end

  def new
    @tracker = @master.trackers.build
    @tracker.event_date = DateTime.now
    render partial: 'edit_form'
    end

  def edit
    render partial: 'edit_form'
  end

  def create
    @tracker = @master.trackers.build(tracker_params)
    @protocol = Protocol.find(tracker_params[:protocol_id])
    @tracker.protocol = @protocol
    if @tracker.save
      show
    else
      logger.warn "Error creating tracker: #{@tracker.errors.inspect}"
      render json: @tracker.errors, status: :unprocessable_entity     
    end
  end

  def update
    if @tracker.update(tracker_params)
      show
    else
      logger.warn "Error updating player info: #{@tracker.errors.inspect}"
      render json: @tracker.errors, status: :unprocessable_entity 
    end
  end

  def destroy
    not_authorized
  end

  private
    def set_tracker
      return if params[:id] == 'cancel'

      @tracker = Tracker.find(params[:id])
    end

    def tracker_params
      params.require(:tracker).permit(:master_id,  :protocol_id, :event, :event_date, :c_method, :outcome, :outcome_date, :user_id)
    end
end
