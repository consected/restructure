class ScantronsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :set_scantron, only: [:show, :edit, :update, :destroy]

  # GET /scantrons
  # GET /scantrons.json
  def index
    @scantrons = Scantron.all
  end

  # GET /scantrons/1
  # GET /scantrons/1.json
  def show
  end

  # GET /scantrons/new
  def new
    @scantron = Scantron.new
  end

  # GET /scantrons/1/edit
  def edit
  end

  # POST /scantrons
  # POST /scantrons.json
  def create
    @scantron = Scantron.new(scantron_params)

    respond_to do |format|
      if @scantron.save
        format.html { redirect_to @scantron, notice: 'Scantron was successfully created.' }
        format.json { render :show, status: :created, location: @scantron }
      else
        format.html { render :new }
        format.json { render json: @scantron.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scantrons/1
  # PATCH/PUT /scantrons/1.json
  def update
    respond_to do |format|
      if @scantron.update(scantron_params)
        format.html { redirect_to @scantron, notice: 'Scantron was successfully updated.' }
        format.json { render :show, status: :ok, location: @scantron }
      else
        format.html { render :edit }
        format.json { render json: @scantron.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scantrons/1
  # DELETE /scantrons/1.json
  def destroy
    @scantron.destroy
    respond_to do |format|
      format.html { redirect_to scantrons_url, notice: 'Scantron was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scantron
      @scantron = Scantron.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scantron_params
      params.require(:scantron).permit(:master_id, :scantron_id, :source, :rank, :user_id)
    end
end
