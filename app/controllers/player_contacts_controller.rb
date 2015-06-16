class PlayerContactsController < ApplicationController
  
  include MasterHandler
  before_action :set_player_contact, only: [:show]

  
  def show
    p = {player_contact: @player_contact.as_json}
    
    
    logger.info p.as_json
    render json: p
  end

  def new
    @player_contact = @master.player_contacts.build
    render partial: 'edit_form'
  end

  def edit
    render partial: 'edit_form'
  end

  def create
  
    @player_contact = @master.player_contacts.build(player_contact_params)

    if @player_contact.save
      show
    else
      logger.warn "Error creating player contact: #{@master.errors.inspect}"
      render json: @master.errors, status: :unprocessable_entity     
    end
  end

  def update
    if @player_contact.update(player_contact_params)
      show
    else
      logger.warn "Error updating player contact: #{@player_contact.errors.inspect}"
      render json: @player_contact.errors, status: :unprocessable_entity 
    end
    
  end

  def destroy
    not_authorized
  end

  private
    def set_player_contact
      return if params[:id] == 'cancel'

      @player_contact = PlayerContact.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def player_contact_params
      params.require(:player_contact).permit(:master_id, :data, :pcdata, :source, :rank, :pcdate, :active)
    end
end
