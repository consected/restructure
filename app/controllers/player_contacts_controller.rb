class PlayerContactsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :set_player_contact, only: [:show, :edit, :update, :destroy]

  # GET /player_contacts
  # GET /player_contacts.json
  def index
    @player_contacts = PlayerContact.all
  end

  # GET /player_contacts/1
  # GET /player_contacts/1.json
  def show
  end

  # GET /player_contacts/new
  def new
    @player_contact = PlayerContact.new
  end

  # GET /player_contacts/1/edit
  def edit
  end

  # POST /player_contacts
  # POST /player_contacts.json
  def create
    @player_contact = PlayerContact.new(player_contact_params)

    respond_to do |format|
      if @player_contact.save
        format.html { redirect_to @player_contact, notice: 'Player contact was successfully created.' }
        format.json { render :show, status: :created, location: @player_contact }
      else
        format.html { render :new }
        format.json { render json: @player_contact.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /player_contacts/1
  # PATCH/PUT /player_contacts/1.json
  def update
    respond_to do |format|
      if @player_contact.update(player_contact_params)
        format.html { redirect_to @player_contact, notice: 'Player contact was successfully updated.' }
        format.json { render :show, status: :ok, location: @player_contact }
      else
        format.html { render :edit }
        format.json { render json: @player_contact.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /player_contacts/1
  # DELETE /player_contacts/1.json
  def destroy
    @player_contact.destroy
    respond_to do |format|
      format.html { redirect_to player_contacts_url, notice: 'Player contact was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player_contact
      @player_contact = PlayerContact.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def player_contact_params
      params.require(:player_contact).permit(:master_id, :data, :pcdata, :source, :rank, :pcdate, :active)
    end
end
