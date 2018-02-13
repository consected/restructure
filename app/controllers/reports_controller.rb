class ReportsController < ApplicationController
  include MasterSearch
  before_action :init_vars
  before_action :authenticate_user_or_admin!
  before_action :authorized?, only: [:index]
  before_action :set_report, only: [:show]
  before_action :set_editable_instance_from_id, only: [:edit, :update]
  after_action :clear_results, only: [:show, :run]

  helper_method :filters, :filters_on, :index_path, :permitted_params
  ResultsLimit = Master.results_limit

  # List of available reports
  def index
    @no_create = true
    pm = Report.enabled.for_user(current_user)
    pm = pm.where filter_params if filter_params

    @reports = pm.order  auto: :desc, report_type: :asc, position: :asc

    respond_to do |format|
      format.html { render :index }
      format.all { render json: @reports.as_json(except: [:created_at, :updated_at, :id, :admin_id, :user_id])}
    end
  end



  def show

    options = {}
    search_attrs = params[:search_attrs]

    @view_context = params[:view_context]
    if @view_context.blank?
      @view_context = nil
    else
      @view_context = @view_context.to_sym
    end

    if params[:commit] == 'count'
      options[:count_only] = true
      @count_only = true
    end

    if search_attrs && search_attrs.is_a?(Hash)
      options[:filter_previous] = true if search_attrs[:_filter_previous_]=='true'
      no_run = !search_attrs[:no_run].blank?
    end

    @editable = @report.editable_data? && (current_admin || current_user && current_user.can?(:edit_report_data))


    return unless @report.searchable.for_user(current_user) || authorized?

    if search_attrs && !no_run
      begin
        @results =  @report.run(search_attrs, options)
      rescue ActiveRecord::PreparedStatementInvalid => e
        logger.info "Prepared statement invalid in reports_controller (#{search_attrs}) show: #{e.inspect}\n#{e.backtrace.join("\n")}"
        @results = nil
        flash.now[:danger] = "Generated SQL invalid.\n#{@report.clean_sql}\n#{e.to_s}"
        respond_to do |format|
          format.html {
            if params[:part] == 'results'
              render plain: "Generated SQL invalid.\n#{@report.clean_sql}\n#{e.to_s}", status: 400
            else
              render :show
            end
          }
          format.json {

            return general_error "invalid query for report. Please check search fields or try to run the report again."

          }
        end
        return
      end

      if params[:commit] == 'search'
        run 'REPORT'
        return
      end


      respond_to do |format|
        format.html {
          if params[:part] == 'results'
            render partial: 'results'
          else
            render :show
          end
        }
        format.json {
          render json: {results: @results, search_attributes: @report.search_attr_values}
        }
        format.csv {
          res_a = []

          blank_value = nil
          if params[:csv_blank]
            blank_value = ""
          end

          res_a << @results.fields.to_csv
          @results.each_row do |row|
            res_a << (row.collect {|val|  val || blank_value}).to_csv
          end



          send_data res_a.join(""), filename: "report.csv"
        }
      end
    elsif params[:get_filter_previous]
      render partial: 'filter_on'
    else
      @report.search_attr_values = search_attrs
      respond_to do |format|
        format.html {
          if params[:part] == 'form'
            render partial: 'form'
          else
            render :show
          end
        }
      end
    end


  end


  def edit
    render partial: 'edit_form'
  end

  def update
    if @report_item.respond_to? :master
      @master = @report_item.master
      @master.current_user = current_user if @master
    elsif @report_item.respond_to? :user_id
      @report_item.user_id = current_user.id
    end
    return not_authorized unless @report.editable_data?

    if @report_item.update(secure_params)
      #redirect_to show_path(id: @report.id), notice: "#{@report_item.human_name} updated successfully"
      #render partial: 'edit_form'
      # Need to update the master_id manually, since it could have been set by a trigger
      res = @report_item.class.find(@report_item.id)
      @report_item.master_id = res.master_id if res.respond_to?(:master_id) && res.master_id
      render json: {report_item: @report_item}
    else
      logger.warn "Error updating #{@report_item}: #{@report_item.errors.inspect}"
      flash.now[:warning] = "Error updating #{@report_item}: #{error_message}"
      edit
    end

  end



  protected

    def set_report
      id = params[:id]
      redirect_to :index if id.blank?
      id = id.to_i
      redirect_to :index unless id > 0

      @report = Report.find(id)
      @report.current_user = current_user

    end


    def error_message
      res = ""
      @report_item.errors.full_messages.each do |message|
        res << "; " unless res.blank?
        res << "#{message}"
      end
      res
    end

    def filters_on
      :item_type
    end

    def filters
      Report.categories.map {|g| [g,g.to_s.humanize]}.to_h
    end


    def filter_params
      return nil if params[:filter].blank?
      params.require(:filter).permit(filters_on)
    end



    def connection
      @connection ||= ActiveRecord::Base.connection
    end

    def clear_results
      # Needed to help control memory usage, according to PG:Result documentation
      @results.clear if @results
    end

    def authorized?
      return true if current_admin
      return true if current_user.can? :view_reports

      return not_authorized
    end

    def index_path p
      reports_path p
    end


    ### For editable reports

    def permitted_params
      @permitted_params = @report.edit_fields
    end

    def secure_params
      params.require(report_params_holder).permit(*permitted_params)
    end


    def set_editable_instance_from_id
      id = params[:report_id]
      id = id.to_i
      @report = Report.find(id)
      return if params[:id] == 'cancel'
      @report_item = report_model.find(params[:id])
      @id = @report_item.id
    end

    def report_model
      @report.edit_model_class
    end

    def report_params_holder
      "report_#{@report.edit_model.classify.underscore}"
    end


    def init_vars
      instance_var_init :results
      instance_var_init :count_only
    end
end
