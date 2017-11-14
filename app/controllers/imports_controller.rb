class ImportsController < ApplicationController

  include ParentHandler
  before_action :authenticate_user_or_admin!
  before_action :authorized?


  before_action :set_import, only: [:show, :edit, :update, :destroy]

  helper_method :permitted_params, :fields, :name


  # Show previous uploads
  def index
    if params[:get_template_for].blank?
      respond_to do |format|
        format.csv {
          raise FphsException.new('Select a table to export')
        }
        format.html {
          @primary_tables = Import.accepts_models

          setup_table_rules

          if current_admin
            @imports = Import.all
          elsif current_user
            @imports = Import.where("user_id=? AND imported_items is not NULL", current_user.id).order(created_at: :desc).limit(10)
          end
        }
      end
    else
      respond_to do |format|
        format.csv {
          m = params[:get_template_for]
          raise "Invalid table selection" unless Import.accepted_model(m)
          @primary_table = m
          # Get an empty list for the model
          res = permitted_params.dup

          send_data res.to_csv, filename: "template_#{m}.csv"

        }
      end
    end
  end

  # Show the results of an upload
  def show
    @primary_table = @import.primary_table

    @import.items = []
    @import.imported_items.each do |id|
      @import.items << item_class.find(id)
    end

    @readonly = true
  end

  # Select a model and file to upload
  def new
    @primary_tables = Import.accepts_models
    @primary_table = params[:primary_table]  if @primary_tables.include? params[:primary_table]
    @import = Import.new
  end

  # Accepts an uploaded file and parses the CSV
  def create
    if params[:import_file] && params[:primary_table]
      @primary_tables = Import.accepts_models
      @primary_table = params[:primary_table] if @primary_tables.include? params[:primary_table]
      uploaded_io = params[:import_file]
      csv = uploaded_io.read
      filename = uploaded_io.original_filename
      @import = Import.import_csv(csv, @primary_table, current_user, filename)

      if @import.persisted?
        render 'new_import'
      else
        redirect_to new_import_path, alert: "Error preparing the import: #{Application.record_error_message @import}"
      end
    else
      redirect_to new_import_path, notice: 'Ensure that a file and table are set'
    end
  end

  # PATCH/PUT /imports/1
  def update

    @primary_table = @import.primary_table

    item_count = 0
    items = []
    errors = []
    failed = false

    import_params["#{@primary_table}_attributes".to_sym].each do |k,c|      
      r = item_class.new c
      @import.attempt_match_on_secondary_key r
      r.master.current_user = current_user if r.master && !r.master_user
      if r.check_valid?
        begin
          r.save!
        rescue => e
          failed = true
          logger.debug "------------------------>Failed to add item to import when saving: #{e}"
        end
      else
        failed = true
        errors << r.errors.first
        logger.debug "------------------------>Failed to add item to import during validation: #{errors.last}"
      end
      items << r
      item_count += 1
    end


    begin
      unless failed
        @import.item_count = item_count
        @import.imported_items = items.map(&:id)
        @import.update(import_params)

        redirect_to @import
        return
      end
    rescue => e
      failed = true
      logger.debug "Error in import update: #{e}\n#{ e.backtrace.join("\n")}"
    end

    if failed
      @import.items = items
      render 'new_import'
    end
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
      (permitted_params ).map(&:to_sym)
    end

    def name
      @primary_table.singularize
    end

    def item_class
      name.ns_camelize.ns_constantize
    end

    def setup_table_rules
      @table_rules = {}
      @primary_tables.each do |tn|
        @primary_table = tn
        @table_rules[tn] = {}
        t = @table_rules[tn]

        pp = permitted_params
        if pp
          pp.each do |p|
            t[p] = p
            col = item_class.columns_hash[p]
            if col
              t[col.type] ||= []
              t[col.type] << p

              if p.start_with?('set_related_')
                t['set_related_field'] ||= []
                t['set_related_field'] << p
              end
            end
          end

          sk= nil
          sk = item_class.parent_secondary_key if item_class.respond_to? :parent_secondary_key
          if sk
            t['secondary_key'] = sk
          end
          if item_class.attribute_names.include?('rec_type')
            t['rec_type'] = 'data'
          end
        end
      end

    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_import
      @import = Import.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def import_params

      params.require(:import).permit(:primary_table, :item_count, :filename, :items, :user_id, item_parameters)
    end

    def authorized?
      return true if current_admin
      return true if current_user.can? :import_csv

      return not_authorized
    end
end
