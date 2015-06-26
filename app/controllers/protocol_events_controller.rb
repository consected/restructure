class ProtocolEventsController < ApplicationController
  before_action :set_protocol_event, only: [:show, :edit, :update, :destroy]

  # GET /protocol_events
  # GET /protocol_events.json
  def index
    @protocol_events = ProtocolEvent.all
  end

  # GET /protocol_events/1
  # GET /protocol_events/1.json
  def show
  end

  # GET /protocol_events/new
  def new
    @protocol_event = ProtocolEvent.new
  end

  # GET /protocol_events/1/edit
  def edit
  end

  # POST /protocol_events
  # POST /protocol_events.json
  def create
    @protocol_event = ProtocolEvent.new(protocol_event_params)

    respond_to do |format|
      if @protocol_event.save
        format.html { redirect_to @protocol_event, notice: 'Protocol event was successfully created.' }
        format.json { render :show, status: :created, location: @protocol_event }
      else
        format.html { render :new }
        format.json { render json: @protocol_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /protocol_events/1
  # PATCH/PUT /protocol_events/1.json
  def update
    respond_to do |format|
      if @protocol_event.update(protocol_event_params)
        format.html { redirect_to @protocol_event, notice: 'Protocol event was successfully updated.' }
        format.json { render :show, status: :ok, location: @protocol_event }
      else
        format.html { render :edit }
        format.json { render json: @protocol_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /protocol_events/1
  # DELETE /protocol_events/1.json
  def destroy
    @protocol_event.destroy
    respond_to do |format|
      format.html { redirect_to protocol_events_url, notice: 'Protocol event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_protocol_event
      @protocol_event = ProtocolEvent.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def protocol_event_params
      params.require(:protocol_event).permit(:name, :protocol_id, :user_id)
    end
end
