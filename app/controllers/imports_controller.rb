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
    if params[:primary_table]
      @primary_tables = Import.accepts_models
      @primary_table = params[:primary_table] if @primary_tables.include? params[:primary_table]
      filename = ''
      if params[:import_file]
        uploaded_io = params[:import_file]
        csv = uploaded_io.read
        filename = uploaded_io.original_filename
      end
      @import = Import.setup_import(@primary_table, current_user, filename)

      if params[:import_file]
        @import.import_csv csv
      else
        @import.item_count = 0
      end

      @blanks = 100 - @import.item_count
      if @blanks > 0
        @import.generate_blank_items @blanks
      else
        @blanks = 0
      end

      if @import.persisted?
        unless @import.errors.empty?
          flash.now[:warning] = @import.errors.to_a.join("\n")[0..2000]
        end
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

    prev_invalid_items = params[:invalid_items].to_i

    @primary_table = @import.primary_table

    item_count = 0
    items = []
    errors = []
    failed = false

    item_class.transaction do

      import_params["#{@primary_table}_attributes".to_sym].each do |k,c|
        r = item_class.new c
        begin
          @import.attempt_match_on_secondary_key r

        rescue FphsException => e
          errors << e.message
          failed = true
        end

        r.master.current_user = current_user if r.master && !r.master_user

        non_blank = false
        r.attribute_names.each do |a|
          non_blank ||= !c[a.to_sym].blank?
        end


        if non_blank
          item_count += 1

          if r.check_valid?
            begin
              r.save!
            rescue => e
              failed = true
              em = r.errors.first || e.to_s
              errors << em
              logger.debug "------------------------>Failed to add item to import when saving: #{e}"
            end
          else
            failed = true
            em = r.errors.first || e.to_s
            errors << em
            logger.debug "------------------------>Failed to add item to import during validation: #{errors.last}"
          end
        else
          # Ensure the blank items are truly blanked out
          r.attribute_names.each do |a|
            r[a] = nil
          end
        end


        items << r

      end


      begin
        # No validations failed and previously none had, plus the number of rows is still the same, so finally submit the import
        if !failed && prev_invalid_items == 0 && item_count == @import.item_count
          @import.item_count = item_count
          @import.imported_items = items.select{|i| !!i.id }.map(&:id)
          @import.update(import_params)
          @complete = true
          redirect_to @import
          return
        end
      rescue => e
        failed = true
        logger.debug "Error in import update: #{e}\n#{ e.backtrace.join("\n")}"
      end

      # Either validations failed, rows were added, or previously some validations had failed
      # so we get a chance to review the correct data

      raise ActiveRecord::Rollback, "Don't save incomplete data"

    end
    rescue => e
      logger.info "Rollback the transaction in imports update based on #{e.message}"
    ensure
      return if @complete
      if errors.empty? && (prev_invalid_items != 0 || @import.item_count.nil?)
        flash.now[:notice] = "Newly entered data has been validated and matched. Check the data is correct and submit again."
      else
        flash.now[:warning] = errors.uniq.join("\n")[0..2000]
      end

      @import.items = items
      @import.item_count = item_count
      @import.save
      render 'new_import'
  end


  protected
    def item_parameters
      item = {}
      item["#{@primary_table}_attributes".to_sym] = fields
      item
    end

    def permitted_params include_alt_ids=true
      Import.permitted_params_for @primary_table, include_alt_ids
    end

    def fields
      if @readonly
        (permitted_params false).map(&:to_sym)
      else
        (permitted_params).map(&:to_sym)
      end
    end

    def name
      @primary_table.singularize
    end

    def item_class
      name.ns_camelize.ns_constantize
    end

    def setup_table_rules
      @table_rules = {}
      gsit = GeneralSelection.enabled.pluck(:item_type).uniq
      @primary_tables.each do |tn|
        @primary_table = tn
        if tn.start_with?('activity_log__')
          altn = tn
        else
          altn = nil
        end

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

              i = "#{tn}_#{p}"
              if gsit.include?(i)
                t[i] = i
              end
              if altn
                i = "#{altn.singularize}_#{p}"
                if gsit.include?(i)
                  t[i] = p
                end
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

    def no_action_log
      true
    end
end
