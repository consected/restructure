# frozen_string_literal: true

class ReportsController < UserBaseController
  include MasterSearch

  before_action :authenticate_user_or_admin!
  before_action :index_authorized?, only: [:index]
  before_action :setup_report, only: [:show]
  before_action :set_editable_instance_from_id, only: %i[edit update new create]
  before_action :set_instance_from_build, only: %i[new create]
  before_action :set_master_and_user, only: %i[create update]
  after_action :clear_results, only: %i[show run]

  helper_method :filters, :filters_on, :index_path, :permitted_params, :filter_params_permitted, :filter_params,
                :search_attrs_params_hash, :embedded_report, :object_instance
  ResultsLimit = Master.results_limit

  attr_accessor :failed

  # List of available reports
  def index
    @no_masters = true

    pm = @all_reports_for_user = Report.enabled.for_user(current_user)
    pm = filtered_primary_model(pm)

    @reports = pm.order auto: :desc, report_type: :asc, position: :asc
    @reports = @reports.reject { |r| r.report_options.list_options.hide_in_list }

    respond_to do |format|
      format.html { render :index }
      format.all { render json: @reports.as_json(except: %i[created_at updated_at id admin_id user_id]) }
    end
  end

  # Run report
  def show
    return not_authorized unless @report.can_access?(current_user) || current_admin

    @results_target = 'master_results_block'

    setup_data_reference_request

    return if failed

    @view_context = params[:view_context].blank? ? nil : params[:view_context].to_sym

    if params[:commit] == 'count'
      @no_masters = true
      @runner.count_only = true
    end

    @force_run = params[:force_run] == 'true'

    unless (@report.searchable || show_authorized?) && (current_admin || @report.can_access?(current_user))
      @no_masters = true
      return
    end

    if params[:search_attrs] && !no_run && (params[:commit].present? || params[:format].present?)
      # Search attributes or data reference parameters have been provided
      # and the query should be run
      begin
        @results = @runner.run(search_attrs_params_hash, current_admin)

        if params[:commit] == 'search'
          # Based on the results for the report, the MasterHandler uses the ids returned to
          # get the results as a masters search, allowing it to be viewed as a search rather
          # than tabular report.
          run 'REPORT'
          return
        end
      rescue ActiveRecord::PreparedStatementInvalid => e
        handle_bad_search_query(e)
        return
      end

      return unless show_authorized? == true

      respond_to do |format|
        format.html do
          if view_mode == 'results'
            render partial: 'results'
          else
            @report_criteria = true
            show_report
          end
        end
        format.json do
          render_json
        end
        format.csv do
          send_csv
        end
      end

      @master_ids = @results.map { |r| r['master_id'] } if @results
    elsif params[:get_filter_previous]
      return unless show_authorized? == true

      @no_masters = true
      render partial: 'filter_on'
    else
      @no_masters = true
      @runner.search_attr_values = search_attrs_params_hash

      begin
        respond_to do |format|
          format.html do
            if view_mode == 'form'
              render partial: 'form'
            else
              return unless show_authorized? == true

              @report_criteria = true
              show_report
            end
          end
          format.json do
            render_json
          end
          format.csv do
            send_csv
          end
        end
      rescue StandardError => e
        raise e
      end
    end
  end

  def edit
    render partial: 'edit_form'
  end

  def new
    render partial: 'edit_form'
  end

  def update
    return not_authorized unless @report.editable_data?

    if @report_item.update(secure_params)
      refresh_updated_data
      render json: { report_item: @report_item }
    else
      logger.warn "Error updating #{@report_item}: #{@report_item.errors.inspect}"
      flash.now[:warning] = "Error updating #{@report_item}: #{error_message}"
      edit
    end
  end

  def create
    if @report_item.save
      refresh_updated_data
      render json: { report_item: @report_item }
    else
      logger.warn "Error creating #{@report_item}: #{@report_item.errors.inspect}"
      flash.now[:warning] = "Error creating #{@report_item}: #{error_message}"
      edit
    end
  end

  def add_to_list
    atl_params = params[:add_to_list]
    list = Reports::ReportList.setup atl_params[:list_name], atl_params[:items], current_user, current_admin

    n = list.add_items_to_list

    res = { flash_message_only: "Added #{n} #{'item'.pluralize(n)} to the list" }
    render json: res
  end

  def update_list
    atl_params = params[:update_list]
    list = Reports::ReportList.setup atl_params[:list_name], atl_params[:items], current_user, current_admin

    n = list.update_items_in_list

    res = { flash_message_only: "Updated #{n} #{'item'.pluralize(n)} in the list" }
    render json: res
  end

  def remove_from_list
    atl_params = params[:remove_from_list]
    list = Reports::ReportList.setup atl_params[:list_name], atl_params[:items], current_user, current_admin

    ids = list.remove_items_from_list
    n = ids.length

    render json: { flash_message_only: "Removed #{n} #{'item'.pluralize(n)} from the list.", removed_id: ids }
  end

  protected

  # Allows edit fields to reference the report
  def object_instance
    @report_item
  end

  def no_create
    true
  end

  def set_master_and_user
    return unless @report_item

    if @report_item.respond_to?(:master) && !@report_item.class.no_master_association
      @master = @report_item.master
      @master.current_user = current_user if @master
    elsif @report_item.respond_to? :current_user
      @report_item.current_user = current_user
    elsif @report_item.respond_to? :user_id
      @report_item.user_id = current_user.id
    end

    @report_item.current_user = current_user if @report_item.respond_to? :current_user=
  end

  def set_instance_from_build
    build_with = begin
      secure_params
    rescue StandardError
      nil
    end

    @report_item = if report_model.respond_to?(:no_master_association) && report_model.no_master_association ||
                      !report_model.respond_to?(:master)
                     report_model.new(build_with)
                   else
                     @master.send(report_model.to_s.ns_underscore.pluralize).build(build_with)
                   end
  end

  # :id parameter can be either an integer ID, or a string, which looks up a item_type__short_name
  # By default it uses the params[:id] for the id, but specifying id as the argument will use this instead
  # @param id [(optional) Intger | String]
  def setup_report(id = nil)
    id ||= params[:id]
    redirect_to :index if id.blank?
    @report = Report.find_by_id_or_resource_name(id)
    @report.current_user = current_user
    @runner = @report.runner
  end

  def setup_data_reference_request
    table_name = params[:table_name]
    schema_name = params[:schema_name]
    table_fields = '*' if params[:table_fields].blank?

    return unless table_name && schema_name

    unless current_user.can?(:view_data_reference) || current_admin
      self.failed = true
      not_authorized
      return
    end

    @runner.data_reference.init(table_name: table_name,
                                schema_name: schema_name,
                                table_fields: table_fields)
  end

  def show_report
    @runner.search_attr_values ||= search_attrs_params_hash
    @report_page = !embedded_report

    if embedded_report
      @results_target = 'embed_results_block'
      render partial: 'show'
    else
      render :show
    end
  end

  def error_message
    res = ''
    @report_item.errors.full_messages.each do |message|
      res += '; ' unless res.blank?
      res += message.to_s
    end
    res
  end

  def filters_on
    [:item_type]
  end

  def filters
    cats = if @all_reports_for_user
             @all_reports_for_user.pluck(:item_type).compact.uniq
           else
             Report.categories
           end

    r_cat = cats.map { |g| [g, g.to_s.humanize] }

    { item_type: r_cat.to_h }
  end

  def filter_defaults
    { item_type: app_config_text(:default_report_tab, nil) }
  end

  def connection
    @connection ||= ActiveRecord::Base.connection
  end

  def clear_results
    # Needed to help control memory usage, according to PG:Result documentation
    @results&.clear
  end

  #
  # Allow users to view a report if they have user access control
  # read / general / view_reports or view_report_not_list
  # @return [true | nil] <description>
  def show_authorized?
    return true if current_admin
    return true if current_user.can?(:view_report_not_list) || current_user.can?(:view_reports)

    self.failed = true
    not_authorized
    throw(:abort)
  end

  #
  # Allow users to see index of reports if they have user access control
  # read / general / view_reports
  # @return [true | nil] <description>
  def index_authorized?
    return true if current_admin
    return true if current_user.can?(:view_reports)

    self.failed = true
    not_authorized
    throw(:abort)
  end

  def index_path(par)
    reports_path par
  end

  def handle_bad_search_query(exception)
    logger.info "Prepared statement invalid in reports_controller (#{search_attrs_params_hash}) show: " \
                "#{exception.inspect}\n#{exception.backtrace.join("\n")}"
    @results = nil
    @no_masters = true
    flash.now[:danger] = "Generated SQL invalid.\n#{@runner.sql}\n#{exception}"
    respond_to do |format|
      format.html do
        if view_mode == 'results'
          render plain: "Generated SQL invalid.\n#{@runner.sql}\n#{exception}", status: 400
        else
          show_report
        end
      end
      format.json do
        return general_error 'invalid query for report. Please check search fields or try to run the report again.'
      end
    end
  end

  def view_mode
    params[:part]
  end

  ### For editable reports

  def permitted_params
    @permitted_params = @report.edit_fields

    @permitted_params = refine_permitted_params(@permitted_params)
  end

  #
  # Permitted parameters for strong param whitelist are generated based on
  # the "edit field" configuration.
  # Ensure that database columns that are defined as array type can receive
  # arrays in the permitted params by checking the actual column definition
  # and changing the permitted param to an array if necessary
  # @param [Array] param_list - the standard list of params to allow
  # @return [Array] the refined resulting permitted params definition
  def refine_permitted_params(param_list)
    res = param_list.dup

    ms_keys = res.select { |a| report_model.columns_hash[a.to_s]&.array }
    ms_keys.each do |k|
      res.delete(k)
      res << { k => [] }
    end

    res
  end

  def secure_params
    @secure_params ||= params.require(report_params_holder).permit(*permitted_params)
  end

  def set_editable_instance_from_id
    id = params[:report_id]
    setup_report id

    return if params[:id] == 'cancel' || params[:id].blank?

    id = params[:id]
    id = id.to_i
    @report_item = report_model.find(id)
    @id = @report_item.id
  end

  def report_model
    @report.edit_model_class
  end

  def report_params_holder
    report_model.to_s.ns_underscore.gsub('__', '_')
  end

  #
  # Permit everything, since this is not used for assignment.
  # If the search_attrs param is a string, just return it
  def search_attrs_params_hash
    @search_attrs_params_hash ||= if params[:search_attrs].nil? || params[:search_attrs] == '_use_defaults_'
                                    @runner.using_defaults = true
                                    { _use_defaults_: '_use_defaults_' }
                                  else
                                    params.require(:search_attrs).permit!.to_h.dup
                                  end
  end

  def embedded_report
    @embedded_report ||= (params[:embed] == 'true')
  end

  def no_run
    @no_run ||= search_attrs_params_hash[:no_run] == 'true'
  end

  #
  # Update the updated or created report item to ensure the response shows correctly,
  # based on the user privileges and any selection options that need to be replaced
  def refresh_updated_data
    if @report_item.respond_to?(:master_id) && @report_item.respond_to?(:id)
      # Need to update the master_id manually, since it could have been set by a trigger
      res = @report_item.class.find(@report_item.id)
      @report_item.master_id = res.master_id if res.master_id
    end

    # Run through each column option and handle those that request 'choice_label'
    # to replace results that are selection based.
    sa = @report.report_options.column_options.show_as
    return unless sa

    sa.each do |col_name, show_as|
      cell_content = @report_item[col_name]
      next unless cell_content && show_as.in?(['choice_label', 'tags'])

      if cell_content.is_a? Array
        @report_item[col_name] = []
        cell_content.each do |cell_content_item|
          @report_item[col_name] << result_for_content_item(col_name, cell_content_item)
        end
      else
        @report_item[col_name] = result_for_content_item(col_name, cell_content)
      end
    end
  end

  #
  # Get a value to appear in a call, find the appropriate label(s) for a select or tag select item
  # @param [String] col_name
  # @param [Object] cell_content
  # @return [Object] - the value for the cell, or an individual item if an array element was passed in
  def result_for_content_item(col_name, cell_content)
    selection_options = helpers.selection_options_handler_for(@report_item.class.table_name)
    result = selection_options.label_for col_name, cell_content
    result = @report_item.send("#{col_name}_options") if result.nil? && @report_item.respond_to?("#{col_name}_options")
    result
  end

  def send_csv
    res_a = []

    blank_value = nil
    blank_value = '' if params[:csv_blank]

    if @results
      res_a << @results.fields.to_csv
      @results.each_row do |row|
        res_a << (row.collect { |val| val || blank_value }).to_csv
      end
    end

    send_data res_a.join(''), filename: 'report.csv'
  end

  def render_json
    render json: { results: @results,
                   search_attributes: @runner.search_attr_values }
  end
end
