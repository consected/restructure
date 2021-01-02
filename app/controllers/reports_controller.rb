# frozen_string_literal: true

class ReportsController < UserBaseController
  include MasterSearch
  before_action :init_vars
  before_action :authenticate_user_or_admin!
  before_action :index_authorized?, only: [:index]
  before_action :set_report, only: [:show]
  before_action :set_editable_instance_from_id, only: %i[edit update new create]
  before_action :set_instance_from_build, only: %i[new create]
  before_action :set_master_and_user, only: %i[create update]
  after_action :clear_results, only: %i[show run]

  helper_method :filters, :filters_on, :index_path, :permitted_params, :filter_params_permitted
  ResultsLimit = Master.results_limit

  # List of available reports
  def index
    @no_create = true
    @no_masters = true
    @embedded_report = (params[:embed] == 'true')

    pm = @all_reports_for_user = Report.enabled.for_user(current_user)
    pm = filtered_primary_model(pm)

    @reports = pm.order auto: :desc, report_type: :asc, position: :asc
    @reports = @reports.reject { |r| r.list_options.hide_in_list }

    respond_to do |format|
      format.html { render :index }
      format.all { render json: @reports.as_json(except: %i[created_at updated_at id admin_id user_id]) }
    end
  end

  # Run report
  def show
    return not_authorized unless @report.can_access?(current_user) || current_admin

    @results_target = 'master_results_block'
    @embedded_report = (params[:embed] == 'true')

    options = {}
    search_attrs = search_attrs_params_hash
    @search_attrs = search_attrs

    table_name = params[:table_name]
    schema_name = params[:schema_name]

    @view_context = params[:view_context]
    @view_context = if @view_context.blank?
                      nil
                    else
                      @view_context.to_sym
                    end

    if params[:commit] == 'count'
      @no_masters = true
      options[:count_only] = true
      @count_only = true
    end

    if search_attrs&.is_a?(Hash)
      options[:filter_previous] = true if search_attrs[:_filter_previous_] == 'true'
      no_run = !search_attrs[:no_run].blank?
    end

    unless @report.searchable || show_authorized?
      @no_masters = true
      return
    end

    unless current_admin || @report.can_access?(current_user)
      @no_masters = true
      return
    end

    if (search_attrs || table_name && schema_name) && !no_run
      begin
        if table_name && schema_name

          return not_authorized unless current_user.can? :view_data_reference

          search_attrs = '_use_defaults_'

          table_fields = '*' if params[:table_fields].blank?

          @results = @report.run(search_attrs,
                                 table_name: table_name,
                                 schema_name: schema_name,
                                 table_fields: table_fields)
        else
          @results = @report.run(search_attrs, options)
        end

        if params[:commit] == 'search'
          run 'REPORT'
          return
        end
      rescue ActiveRecord::PreparedStatementInvalid => e
        logger.info "Prepared statement invalid in reports_controller (#{search_attrs}) show: #{e.inspect}\n#{e.backtrace.join("\n")}"
        @results = nil
        @no_masters = true
        flash.now[:danger] = "Generated SQL invalid.\n#{@report.clean_sql}\n#{e}"
        respond_to do |format|
          format.html do
            if params[:part] == 'results'
              render plain: "Generated SQL invalid.\n#{@report.clean_sql}\n#{e}", status: 400
            else
              @report.search_attr_values ||= search_attrs
              show_report
            end
          end
          format.json do
            return general_error 'invalid query for report. Please check search fields or try to run the report again.'
          end
        end
        return
      end

      return unless show_authorized? == true

      respond_to do |format|
        format.html do
          if params[:part] == 'results'
            render partial: 'results'
          else
            @report_criteria = true
            @report.search_attr_values ||= search_attrs
            show_report
          end
        end
        format.json do
          render json: { results: @results, search_attributes: @report.search_attr_values }
        end
        format.csv do
          res_a = []

          blank_value = nil
          blank_value = '' if params[:csv_blank]

          res_a << @results.fields.to_csv
          @results.each_row do |row|
            res_a << (row.collect { |val| val || blank_value }).to_csv
          end

          send_data res_a.join(''), filename: 'report.csv'
        end
      end

      @master_ids = @results.map { |r| r['master_id'] } if @results
    elsif params[:get_filter_previous]
      return unless show_authorized? == true

      @no_masters = true
      render partial: 'filter_on'
    else
      @no_masters = true
      @report.search_attr_values = search_attrs

      begin
        respond_to do |format|
          format.html do
            if params[:part] == 'form'
              render partial: 'form'
            else
              return unless show_authorized? == true

              @report_criteria = true

              show_report
            end
          end
          format.json do
            render json: { results: @results, search_attributes: (@report.search_attr_values || search_attrs) }
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
      # Need to update the master_id manually, since it could have been set by a trigger
      res = @report_item.class.find(@report_item.id)
      @report_item.master_id = res.master_id if res.respond_to?(:master_id) && res.master_id
      render json: { report_item: @report_item }
    else
      logger.warn "Error updating #{@report_item}: #{@report_item.errors.inspect}"
      flash.now[:warning] = "Error updating #{@report_item}: #{error_message}"
      edit
    end
  end

  def create
    if @report_item.save
      # Need to update the master_id manually, since it could have been set by a trigger
      res = @report_item.class.find(@report_item.id)
      @report_item.master_id = res.master_id if res.respond_to?(:master_id) && res.master_id

      render json: { report_item: @report_item }
    else
      logger.warn "Error creating #{@report_item}: #{@report_item.errors.inspect}"
      flash.now[:warning] = "Error creating #{@report_item}: #{error_message}"
      edit
    end
  end

  def add_to_list
    atl_params = params[:add_to_list]
    list = Reports::ReportList.setup atl_params, current_user, current_admin

    n = list.add_items_to_list

    res = { flash_message_only: "Added #{n} #{'item'.pluralize(n)} to the list" }
    render json: res
  end

  def update_list
    atl_params = params[:update_list]
    list = Reports::ReportList.setup atl_params, current_user, current_admin

    n = list.update_items_in_list

    res = { flash_message_only: "Updated #{n} #{'item'.pluralize(n)} in the list" }
    render json: res
  end

  def remove_from_list
    atl_params = params[:remove_from_list]
    list = Reports::ReportList.setup atl_params, current_user, current_admin

    ids = list.remove_items_from_list
    n = ids.length

    render json: { flash_message_only: "Removed #{n} #{'item'.pluralize(n)} from the list.", removed_id: ids }
  end

  protected

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

    if report_model.respond_to?(:no_master_association) && report_model.no_master_association || !report_model.respond_to?(:master)
      @report_item = report_model.new(build_with)
    else
      @report_item = @master.send(report_model.to_s.ns_underscore.pluralize).build(build_with)
    end
  end

  # :id parameter can be either an integer ID, or a string, which looks up a item_type__short_name
  # By default it uses the params[:id] for the id, but specifying id as the argument will use this instead
  # @param id [(optional) Intger | String]
  def set_report(id = nil)
    id ||= params[:id]
    redirect_to :index if id.blank?
    num_id = id.to_i
    @report = if num_id > 0
                Report.active.find(num_id)
              else
                Report.active.find_category_short_name id
              end

    @report.current_user = current_user
  end

  def show_report
    @report_page = !@embedded_report

    if @embedded_report
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

    not_authorized
    throw(:abort)
  end

  def index_path(p)
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
    set_report id

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

  def search_attrs_params_hash
    # Permit everything, since this is not used for assignment.
    params.require(:search_attrs).permit!.to_h unless params[:search_attrs].nil? || params[:search_attrs]&.is_a?(String)
  end

  def init_vars
    instance_var_init :results
    instance_var_init :count_only
  end
end
