class ProInfosController < ApplicationController
  before_action :set_pro_info, only: [:show, :edit, :update, :destroy]

  # GET /pro_infos
  # GET /pro_infos.json
  def index
    @pro_infos = ProInfo.all
  end

  # GET /pro_infos/1
  # GET /pro_infos/1.json
  def show
  end

  # GET /pro_infos/new
  def new
    @pro_info = ProInfo.new
  end

  # GET /pro_infos/1/edit
  def edit
  end

  # POST /pro_infos
  # POST /pro_infos.json
  def create
    @pro_info = ProInfo.new(pro_info_params)

    respond_to do |format|
      if @pro_info.save
        format.html { redirect_to @pro_info, notice: 'Pro info was successfully created.' }
        format.json { render :show, status: :created, location: @pro_info }
      else
        format.html { render :new }
        format.json { render json: @pro_info.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pro_infos/1
  # PATCH/PUT /pro_infos/1.json
  def update
    respond_to do |format|
      if @pro_info.update(pro_info_params)
        format.html { redirect_to @pro_info, notice: 'Pro info was successfully updated.' }
        format.json { render :show, status: :ok, location: @pro_info }
      else
        format.html { render :edit }
        format.json { render json: @pro_info.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pro_infos/1
  # DELETE /pro_infos/1.json
  def destroy
    @pro_info.destroy
    respond_to do |format|
      format.html { redirect_to pro_infos_url, notice: 'Pro info was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pro_info
      @pro_info = ProInfo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pro_info_params
      params.require(:pro_info).permit(:master_id, :user_id)
    end
end
