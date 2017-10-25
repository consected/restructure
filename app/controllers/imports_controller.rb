class ImportsController < ApplicationController

  include ParentHandler
  before_action :authenticate_user_or_admin!
  before_action :authorized?


  before_action :set_import, only: [:show, :edit, :update, :destroy]

  helper_method :permitted_params, :fields, :name


  # GET /imports
  def index
    @imports = Import.all
  end

  # GET /imports/1
  def show
  end

  # GET /imports/new
  def new
    @primary_tables = Import.accepts_models
    @import = Import.new

  end

  # GET /imports/1/edit
  def edit
  end

  # POST /imports
  def create
    if params[:import_file] && params[:primary_table]
      @primary_table = params[:primary_table]
      uploaded_io = params[:import_file]
      csv = uploaded_io.read
      @import = Import.import_csv(csv, @primary_table, current_user)
      render 'new_import'
    end
  end

  # PATCH/PUT /imports/1
  def update

    @primary_table = @import.primary_table

    item_count = 0
    items = []
    import_params["#{@primary_table}_attributes".to_sym].each do |k,c|

      r = item_class.new c
      r.master.current_user = current_user
      r.save!
      items << r
      item_count += 1
    end

    @import.item_count = item_count
    @import.imported_items = items.map(&:id)
    if @import.update(import_params)
      redirect_to @import, notice: 'Import was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /imports/1
  def destroy
    @import.destroy
    redirect_to imports_url, notice: 'Import was successfully destroyed.'
  end

  protected
    def item_parameters
      item = {}
      item["#{@primary_table}_attributes".to_sym] = fields
      item
    end

    def permitted_params
      Import.permitted_params_for @primary_table
    end

    def fields
      (permitted_params - ['id', 'user_id', 'created_at', 'updated_at']).map(&:to_sym)
    end

    def name
      @primary_table.singularize
    end

    def item_class
      name.ns_camelize.ns_constantize
    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_import
      @import = Import.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def import_params
      puts item_parameters
      params.require(:import).permit(:primary_table, :item_count, :filename, :items, :user_id, item_parameters)
    end

    def authorized?
      return true if current_admin
      return true if current_user.can? :view_reports

      return not_authorized
    end
end
