# frozen_string_literal: true

class MastersController < UserBaseController
  before_action :init_vars

  before_action :authorized?, only: %i[new create]

  helper_method :embedded_report

  attr_accessor :embedded_report

  include MasterSearch
  include Fphs::PlayerActionHandler

  ResultsLimit = Master.results_limit

  def index
    # search_params
    if search_params.nil? || search_params.empty?
      @no_masters = true
      redirect_to '/masters/search/'
      return
    end

    @search_type = params[:mode]
    @search_type = 'ADVANCED' if @search_type.blank?

    run @search_type
  end

  def show
    @master = Master.find_with params, access_by: current_user
    return not_found unless @master

    req_type = params[:type]
    if req_type && Master.crosswalk_attr?(req_type) && params[:id]
      # The requested type is a master crosswalk attribute.
      @ext_id = @master.attributes[req_type]
      @ext_field = req_type
    elsif req_type && Master.alternative_id?(req_type) && params[:id]
      # The requested type is a master crosswalk attribute.
      @ext_id = params[:id]
      @ext_field = req_type
    elsif params[:id]
      # Not a crosswalk, so the id is a Master id
      @master_id = @master.id
    end
    @master.current_user ||= current_user

    @no_search = app_config_set(:no_search_in_master_record)

    # Allow return of a simple JSON master
    respond_to do |format|
      format.html { search }
      format.json { render json: { master: @master } }
    end
  end

  #
  # Search action for search forms and structured URL query strings.
  #
  # A list of master IDs may be passed in, with the param *nav_q_id*. This is typically
  # used to display the set of master records displayed in a previous search when the
  # user refreshed the page.
  # If the app config :prevent_reload_master_list is set, do not reload
  # the list of masters that were displayed from a previous search. In some scenarios this
  # list will be out of date, or confusing to users.
  #
  # An external ID (or master crosswalk ID) may be used to search instead, using the params
  # external_id[id], external_id[field]. The 'field' param names the alternative ID to use.
  #
  # params[:external_id] - we have an external_id parameter, use this to search
  # params[:nav_q_id] - if not an external_id instead search by master id
  # params[:req_format] - determines the result format. 'reg' for UI, alternatively 'csv' or 'json'
  # If the method build_associations_for_searches is available, use this to setup appropriate
  # associations to support the search.
  def search
    pext = params[:external_id]

    if params[:nav_q_id].present?
      @master_id ||= params[:nav_q_id] unless app_config_text(:prevent_reload_master_list, nil)
      @requested_master = @master_id

    elsif pext
      @ext_field ||= pext[:field]
      named_id = pext.to_unsafe_h.select { |_k, v| v.present? }.first

      if @ext_field.present?
        @ext_id ||= pext[:id]
      elsif named_id
        @ext_field = named_id.first
        @ext_id ||= named_id.last
      end

      @requested_master = Master.find_with_alternative_id(@ext_field, @ext_id, current_user) if @ext_field && @ext_id
    end

    # What format is being requested. If nothing is specified, 'reg' indicates a UI search result
    @master_req_format = params[:req_format] || 'reg'

    @master = Master.new

    # Build supporting search associations if the method is available
    build_associations_for_searches if respond_to? :build_associations_for_searches

    render :search
  end

  def new
    @master = Master.new_master_record current_user
    render :new
  end

  def create
    if Rails.env.test? && params[:commit] == 'Create Empty Master'
      # Test an edge case that requires a completely empty master record to be created, without Player Info
      @master = Master.create_master_record current_user, empty: true
    else
      # Unfortunately there is no easy way to force the create request to fail for the purposes of testing
      # Therefore we provide a way to force an apparent failure in the test environment.
      # This is necessary in order to allow testing of what appears to be a false positive for this action in Brakeman
      unless Rails.env.test? && params[:testfail] == 'testfail'
        wep = params[:master].require(:embedded_item) if params[:master]
        @master = Master.create_master_record current_user, with_embedded_params: wep
      end
    end

    respond_to do |format|
      format.html do
        if @master&.id
          redirect_to master_path(@master.id), notice: "Created Master Record with ID #{@master.id}"
        else
          redirect_to new_master_url,
                      notice: "Error creating Master Record: #{Application.record_error_message @master}"
        end
      end
      format.json do
        if @master&.id
          render json: { master: @master }
        else
          render json: { message: "Error creating Master Record: #{Application.record_error_message @master}" },
                 status: 400
        end
      end
    end
  end

  private

  def init_vars
    instance_var_init :master
    instance_var_init :id
  end

  def search_params
    # Permit everything, since this is not used for assignment.
    p = params.except(:utf8, :controller, :action).permit!.to_h
    p = params_nil_if_blank p
    p = params_downcase p
    logger.debug "Screened params: #{p.inspect}"
    p
  end

  def authorized?
    return true if current_user.can? :create_master

    not_authorized
  end
end
