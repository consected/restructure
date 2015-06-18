class ItemFlagNamesController < ApplicationController
  before_action :authenticate_admin!

  before_action :set_item_flag_name, only: [:show, :edit, :update, :destroy]

  # GET /item_flag_names
  # GET /item_flag_names.json
  def index
    @item_flag_names = ItemFlagName.all
  end

  # GET /item_flag_names/1
  # GET /item_flag_names/1.json
  def show
  end

  # GET /item_flag_names/new
  def new
    @item_flag_name = ItemFlagName.new
  end

  # GET /item_flag_names/1/edit
  def edit
  end

  # POST /item_flag_names
  # POST /item_flag_names.json
  def create
    @item_flag_name = ItemFlagName.new(item_flag_name_params)

    respond_to do |format|
      if @item_flag_name.save
        format.html { redirect_to @item_flag_name, notice: 'Item flag name was successfully created.' }
        format.json { render :show, status: :created, location: @item_flag_name }
      else
        format.html { render :new }
        format.json { render json: @item_flag_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /item_flag_names/1
  # PATCH/PUT /item_flag_names/1.json
  def update
    respond_to do |format|
      if @item_flag_name.update(item_flag_name_params)
        format.html { redirect_to @item_flag_name, notice: 'Item flag name was successfully updated.' }
        format.json { render :show, status: :ok, location: @item_flag_name }
      else
        format.html { render :edit }
        format.json { render json: @item_flag_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /item_flag_names/1
  # DELETE /item_flag_names/1.json
  def destroy
    @item_flag_name.destroy
    respond_to do |format|
      format.html { redirect_to item_flag_names_url, notice: 'Item flag name was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item_flag_name
      @item_flag_name = ItemFlagName.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def item_flag_name_params
      params.require(:item_flag_name).permit(:name, :item_type, :user_id)
    end
end
