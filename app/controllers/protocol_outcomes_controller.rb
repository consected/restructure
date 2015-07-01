class ProtocolOutcomesController < ApplicationController
  before_action :authenticate_admin!

  before_action :set_protocol_outcome, only: [:show, :edit, :update, :destroy]

  # GET /protocol_outcomes
  # GET /protocol_outcomes.json
  def index
    @protocol_outcomes = ProtocolOutcome.all
  end

  # GET /protocol_outcomes/1
  # GET /protocol_outcomes/1.json
  def show
  end

  # GET /protocol_outcomes/new
  def new
    @protocol_outcome = ProtocolOutcome.new
  end

  # GET /protocol_outcomes/1/edit
  def edit
  end

  # POST /protocol_outcomes
  # POST /protocol_outcomes.json
  def create
    @protocol_outcome = ProtocolOutcome.new(protocol_outcome_params)

    respond_to do |format|
      if @protocol_outcome.save
        format.html { redirect_to @protocol_outcome, notice: 'Protocol outcome was successfully created.' }
        format.json { render :show, status: :created, location: @protocol_outcome }
      else
        format.html { render :new }
        format.json { render json: @protocol_outcome.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /protocol_outcomes/1
  # PATCH/PUT /protocol_outcomes/1.json
  def update
    respond_to do |format|
      if @protocol_outcome.update(protocol_outcome_params)
        format.html { redirect_to @protocol_outcome, notice: 'Protocol outcome was successfully updated.' }
        format.json { render :show, status: :ok, location: @protocol_outcome }
      else
        format.html { render :edit }
        format.json { render json: @protocol_outcome.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /protocol_outcomes/1
  # DELETE /protocol_outcomes/1.json
  def destroy
    @protocol_outcome.destroy
    respond_to do |format|
      format.html { redirect_to protocol_outcomes_url, notice: 'Protocol outcome was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_protocol_outcome
      @protocol_outcome = ProtocolOutcome.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def protocol_outcome_params
      params.require(:protocol_outcome).permit(:name, :protocol_id, :admin_id)
    end
end
