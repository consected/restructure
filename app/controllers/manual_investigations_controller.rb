class ManualInvestigationsController < ApplicationController
  before_action :set_manual_investigation, only: [:show, :edit, :update, :destroy]

  # GET /manual_investigations
  # GET /manual_investigations.json
  def index
    @manual_investigations = ManualInvestigation.all
  end

  # GET /manual_investigations/1
  # GET /manual_investigations/1.json
  def show
  end

  # GET /manual_investigations/new
  def new
    @manual_investigation = ManualInvestigation.new
  end

  # GET /manual_investigations/1/edit
  def edit
  end

  # POST /manual_investigations
  # POST /manual_investigations.json
  def create
    @manual_investigation = ManualInvestigation.new(manual_investigation_params)

    respond_to do |format|
      if @manual_investigation.save
        format.html { redirect_to @manual_investigation, notice: 'Manual investigation was successfully created.' }
        format.json { render :show, status: :created, location: @manual_investigation }
      else
        format.html { render :new }
        format.json { render json: @manual_investigation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /manual_investigations/1
  # PATCH/PUT /manual_investigations/1.json
  def update
    respond_to do |format|
      if @manual_investigation.update(manual_investigation_params)
        format.html { redirect_to @manual_investigation, notice: 'Manual investigation was successfully updated.' }
        format.json { render :show, status: :ok, location: @manual_investigation }
      else
        format.html { render :edit }
        format.json { render json: @manual_investigation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /manual_investigations/1
  # DELETE /manual_investigations/1.json
  def destroy
    @manual_investigation.destroy
    respond_to do |format|
      format.html { redirect_to manual_investigations_url, notice: 'Manual investigation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_manual_investigation
      @manual_investigation = ManualInvestigation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def manual_investigation_params
      params.require(:manual_investigation).permit(:fill_in_addresses, :in_survey, :verify_survey_participation, :verify_player_and_or_match, :accuracy, :accuracy_score, :accruedseasons, :first_contract, :second_contract, :third_contract, :changed, :changed_column, :verified, :pilotq1, :mailing, :outreach_vfy, :insert_audit_key, :user_id)
    end
end
