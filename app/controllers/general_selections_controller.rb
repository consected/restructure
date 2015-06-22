class GeneralSelectionsController < ApplicationController

  before_action :authenticate_admin!
  before_action :set_general_selection, only: [:show, :edit, :update, :destroy]

  # GET /general_selections
  # GET /general_selections.json
  def index
    @general_selections = GeneralSelection.all
  end

  # GET /general_selections/1
  # GET /general_selections/1.json
  def show
  end

  # GET /general_selections/new
  def new
    @general_selection = GeneralSelection.new
  end

  # GET /general_selections/1/edit
  def edit
  end

  # POST /general_selections
  # POST /general_selections.json
  def create
    @general_selection = GeneralSelection.new(general_selection_params)

    respond_to do |format|
      if @general_selection.save
        format.html { redirect_to @general_selection, notice: 'General selection was successfully created.' }
        format.json { render :show, status: :created, location: @general_selection }
      else
        format.html { render :new }
        format.json { render json: @general_selection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /general_selections/1
  # PATCH/PUT /general_selections/1.json
  def update
    respond_to do |format|
      if @general_selection.update(general_selection_params)
        format.html { redirect_to @general_selection, notice: 'General selection was successfully updated.' }
        format.json { render :show, status: :ok, location: @general_selection }
      else
        format.html { render :edit }
        format.json { render json: @general_selection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /general_selections/1
  # DELETE /general_selections/1.json
  def destroy
    @general_selection.destroy
    respond_to do |format|
      format.html { redirect_to general_selections_url, notice: 'General selection was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_general_selection
      @general_selection = GeneralSelection.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def general_selection_params
      params.require(:general_selection).permit(:name, :value, :item_type)
    end
end
