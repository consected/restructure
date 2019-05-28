class ReportsController < UserBaseController
  include MasterSearch
  before_action :init_vars
  before_action :authenticate_user_or_admin!
  before_action :authorized?, only: [:index]
  before_action :set_report, only: [:show]
  before_action :set_editable_instance_from_id, only: [:edit, :update, :new, :create]
  before_action :set_instance_from_build, only: [:new, :create]
  before_action :set_master_and_user, only: [:create, :update]
  after_action :clear_results, only: [:show, :run]

  helper_method :filters, :filters_on, :index_path, :permitted_params, :editable?, :creatable?
  ResultsLimit = Master.results_limit

  # List of available reports
  def index
    @no_create = true
    @no_masters = true
    @embedded_report = (params[:embed] == 'true')

    pm = @all_reports_for_user = Report.enabled.for_user(current_user)
    pm = filtered_primary_model(pm)

    @reports = pm.order  auto: :desc, report_type: :asc, position: :asc

    respond_to do |format|
      format.html { render :index }
      format.all { render json: @reports.as_json(except: [:created_at, :updated_at, :id, :admin_id, :user_id])}
    end
  end



  def show

    return not_authorized unless @report.can_access?(current_user) || current_admin

    @results_target = "master_results_block"
    @embedded_report = (params[:embed] == 'true')

    options = {}
    search_attrs = params[:search_attrs]
    @search_attrs = search_attrs

    @view_context = params[:view_context]
    if @view_context.blank?
      @view_context = nil
    else
      @view_context = @view_context.to_sym
    end

    if params[:commit] == 'count'
      @no_masters = true
      options[:count_only] = true
      @count_only = true
    end

    if search_attrs && search_attrs.is_a?(Hash)
      options[:filter_previous] = true if search_attrs[:_filter_previous_]=='true'
      no_run = !search_attrs[:no_run].blank?
    end

    unless @report.searchable || authorized?
      @no_masters = true
      return
    end

    unless current_admin || @report.can_access?(current_user)
      @no_masters = true
      return
    end

    if search_attrs && !no_run
      begin
        @results =  @report.run(search_attrs, options)
      rescue ActiveRecord::PreparedStatementInvalid => e
        logger.info "Prepared statement invalid in reports_controller (#{search_attrs}) show: #{e.inspect}\n#{e.backtrace.join("\n")}"
        @results = nil
        @no_masters = true
        flash.now[:danger] = "Generated SQL invalid.\n#{@report.clean_sql}\n#{e.to_s}"
        respond_to do |format|
          format.html {
            if params[:part] == 'results'
              render plain: "Generated SQL invalid.\n#{@report.clean_sql}\n#{e.to_s}", status: 400
            else
              @report.search_attr_values ||= search_attrs
              show_report
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


      return unless authorized? == true
      respond_to do |format|
        format.html {
          if params[:part] == 'results'
            render partial: 'results'
          else
            @report_criteria = true
            @report.search_attr_values ||= search_attrs
            show_report
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

      @master_ids = @results.map {|r| r['master_id']} if @results
    elsif params[:get_filter_previous]
      return unless authorized? == true
      @no_masters = true
      render partial: 'filter_on'
    else
      @no_masters = true
      @report.search_attr_values = search_attrs
      respond_to do |format|
        format.html {
          if params[:part] == 'form'
            render partial: 'form'
          else
            return unless authorized? == true

            @report_criteria = true

            show_report
          end
        }
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
      render json: {report_item: @report_item}
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

      render json: {report_item: @report_item}
    else
      logger.warn "Error creating #{@report_item}: #{@report_item.errors.inspect}"
      flash.now[:warning] = "Error creating #{@report_item}: #{error_message}"
      edit
    end


  end

  def add_to_list
    atl_params = params[:add_to_list]
    list_name = atl_params[:list_name]
    items_text = atl_params[:items]

    return unless authorized? == true

    ok = current_user.has_access_to?(:create, :table, list_name) || current_user.has_access_to?(:create, :table, "dynamic_model__#{list_name}")
    return not_authorized unless ok

    return general_error("no items selected") if items_text.blank? || items_text.length == 0

    items = items_text.map {|i| JSON.parse(i)}
    item_types = items.map {|i| i["type"]}.uniq
    return general_error("item type not specified") unless item_types.length == 1 && item_types.first
    item_type = item_types.first

    list_ids = items.map {|i| i["list_id"]}.uniq
    list_id = list_ids.first
    return general_error("list id not specified") unless list_ids.length == 1 && list_id

    ok = current_user.has_access_to?(:access, :table, item_type) || current_user.has_access_to?(:access, :table, "dynamic_model__#{item_type}")
    return not_authorized unless ok

    item_ids = items.map {|i| i["id"]}

    item_class = item_type.classify.constantize
    item_attribs = item_class.permitted_params

    list_class = list_name.classify.constantize
    list_attribs = list_class.permitted_params
    assoc_attr = (list_class.attribute_names.select {|a| a.end_with?('_id')} - ['id', 'master_id', 'item_id', 'user_id']).first

    assoc_name = assoc_attr.gsub(/_id$/, '').pluralize
    ok = current_user.has_access_to?(:access, :table, assoc_name) || current_user.has_access_to?(:access, :table, "dynamic_model__#{assoc_name}")
    return not_authorized unless ok


    items_in_list = list_class.where(assoc_attr => list_id).pluck(:item_id)
    item_ids = item_ids - items_in_list
    return general_error("all items already in the list") if item_ids.length == 0

    assoc_class = assoc_name.classify.constantize
    assoc_item = assoc_class.where(id: list_id).first
    return general_error("list id does not represent an associated list: #{list_id}") unless assoc_item

    matching_attribs = (list_attribs & item_attribs).map(&:to_s)
    return general_error("no matching attributes") if matching_attribs.length == 0



    list_class.transaction do
      item_ids.each do |id|
        item = item_class.find(id)
        master = item.master
        master.current_user = current_user
        matched_vals = item.attributes.slice(*matching_attribs)
        matched_vals[:item_id] = id
        matched_vals[:master] = master
        matched_vals[assoc_attr] = list_id
        list_class.create! matched_vals
      end
    end

    n = item_ids.length

    render json: {flash_message_only: "Added #{n} #{"item".pluralize(n)} to the list"}

  end


  protected

    def editable?
      @editable = @report.editable_data? && (current_admin || current_user && current_user.can?(:edit_report_data))
    end

    def creatable?
      @creatable = @report.editable_data? && (current_admin || current_user && current_user.can?(:create_report_data))
    end

    def set_master_and_user

      return unless @report_item
      if @report_item.respond_to?(:master) && !@report_item.class.no_master_association
        @master = @report_item.master
        @master.current_user = current_user if @master
      elsif @report_item.respond_to? :user_id
        @report_item.user_id = current_user.id
      end

      if @report_item.respond_to? :current_user=
        @report_item.current_user = current_user
      end
    end


    def set_instance_from_build

      build_with = secure_params rescue nil

      if report_model.respond_to?(:no_master_association) && report_model.no_master_association || !report_model.respond_to?(:master)
        @report_item = report_model.new(build_with)
      else
        @report_item = @master.send(report_model.to_s.ns_underscore.pluralize).build(build_with)
      end

    end

    def set_report
      id = params[:id]
      redirect_to :index if id.blank?
      id = id.to_i
      redirect_to :index unless id > 0

      @report = Report.find(id)
      @report.current_user = current_user

    end

    def show_report
      @report_page = !@embedded_report

      if @embedded_report
        @results_target = "embed_results_block"
        render partial: 'show'
      else
        render :show
      end
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
      [:item_type]
    end

    def filters

      if @all_reports_for_user
        cats = @all_reports_for_user.pluck(:item_type).compact.uniq
      else
        cats = Report.categories
      end

      r_cat = cats.map {|g| [g,g.to_s.humanize]}


      {item_type: r_cat.to_h}
    end


    # def filter_params
    #   params[:filter] ||= filter_defaults
    #   return nil if params[:filter].blank?
    #   params.require(:filter).permit(filters_on)
    # end

    def filter_defaults
      {item_type: app_config_text(:default_report_tab, nil)}
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
      @report.current_user = current_user
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


    def init_vars
      instance_var_init :results
      instance_var_init :count_only
    end
end
