class PlayerInfosController < ApplicationController
  include MasterHandler
  before_action :set_player_info, only: [:show]

  
  def show
    p = {player_info: @player_info.as_json(include: :pro_info)}
    
    
    logger.info p.as_json
    render json: p
  end

  def new
    @player_info = @master.player_infos.build
    render partial: 'edit_form'
  end

  def edit
    render partial: 'edit_form'
  end

  def create
  
    @player_info = @master.player_infos.build(player_info_params)

    if @player_info.save
      show
    else
      logger.warn "Error creating player info: #{@master.errors.inspect}"
      render json: @master.errors, status: :unprocessable_entity     
    end
  end

  def update
    if @player_info.update(player_info_params)
      show
    else
      logger.warn "Error updating player info: #{@player_info.errors.inspect}"
      render json: @player_info.errors, status: :unprocessable_entity 
    end
    
  end

  def destroy
    not_authorized
  end

  private
    
    def set_player_info    
      return if params[:id] == 'cancel'

      @player_info = PlayerInfo.find(params[:id])            
    end
    
    def player_info_params
      params.require(:player_info).permit(:master_id, :first_name, :last_name, :middle_name, :nick_name, :birth_date, :death_date, :start_year, :rank, :occupation_category, :company, :company_description, :transaction_status, :transaction_substatus, :user_id)
    end
end
