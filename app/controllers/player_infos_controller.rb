class PlayerInfosController < ApplicationController
  include MasterHandler
  before_action :set_player_info, only: [:show, :edit, :update, :destroy]

  before_action :authenticate_user!
  
#  def index
#    @player_infos = PlayerInfo.all
#  end
#
  def show
    render json: {player_info: @player_info}
  end

  def new
    @player_info = @master.player_infos.build
  end

  # GET /player_infos/1/edit
  def edit
    render partial: 'edit_form'
  end

  # POST /player_infos
  # POST /player_infos.json
  def create
  
    @player_info = @master.player_infos.build(player_info_params)

    respond_to do |format|
      if @player_info.save
        format.html { redirect_to @master, notice: 'Player info was successfully created.' }
        format.json { render :show, status: :created, location: @player_info }
      else
        format.html { render :new }
        format.json { render json: @master.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /player_infos/1
  # PATCH/PUT /player_infos/1.json
  def update
    
    respond_to do |format|
      if @player_info.update(player_info_params)
        format.html { redirect_to @player_info, notice: 'Player info was successfully updated.' }
        format.json { render :show, status: :ok, location: @player_info }
      else
        format.html { render :edit }
        format.json { render json: @player_info.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /player_infos/1
  # DELETE /player_infos/1.json
  def destroy
    @player_info.destroy
    respond_to do |format|
      format.html { redirect_to player_infos_url, notice: 'Player info was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player_info    
      @player_info = PlayerInfo.find(params[:id])            
    end
    
    

    # Never trust parameters from the scary internet, only allow the white list through.
    def player_info_params
      params.require(:player_info).permit(:master_id, :first_name, :last_name, :middle_name, :nick_name, :birth_date, :death_date, :occupation_category, :company, :company_description, :transaction_status, :transaction_substatus, :website, :alternate_website, :twitter_id, :user_id)
    end
end
