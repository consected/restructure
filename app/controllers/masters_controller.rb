class MastersController < ApplicationController

  before_action :init_vars
  before_action :authenticate_user!
  before_action :authorized?, only: [:new, :create]
  include MasterSearch


  ResultsLimit = Master.results_limit

  def index

    #search_params
    redirect_to '/masters/search/' and return if search_params.nil? || search_params.length == 0

    search_type = params[:mode]
    search_type = 'ADVANCED' if search_type.blank?


    run search_type


  end

  def show
    if params[:type] == 'msid' && params[:id]
      @master = Master.find_by_msid(params[:id])
      return not_found unless @master
      @msid = @master.msid
    elsif params[:id]
      @master = Master.find(params[:id])
      return not_found unless @master
      @master_id = @master.id
    end

    search

  end

  def search
    @msid ||= params[:nav_q]
    @master_pro_id ||= params[:nav_q_pro_id]
    @master_id ||= params[:nav_q_id]

    @master_req_format = params[:req_format] || 'reg'

    @master =  Master.new

    # Advanced search fields
    @master.pro_infos.build
    @master.player_infos.build
    @master.addresses.build
    @master.player_contacts.build
    @master.trackers.build
    @master.tracker_histories.build
    @master.scantrons.build
    #@master.sage_assignments.build

    # NOT conditions
    @master.not_trackers.build
    @master.not_tracker_histories.build

    # Simple search fields
    @master.general_infos.build


    render :search
  end

  def new
    @master = Master.new
    render :new
  end

  def create

    if Rails.env.test? && params[:commit] == 'Create Empty Master'
      # Test an edge case that requires a completely empty master record to be created, without Player Info
      @master = Master.create_master_records current_user, empty: true
    else
      # Unfortunately there is no easy way to force the create request to fail for the purposes of testing
      # Therefore we provide a way to force an apparent failure in the test environment.
      # This is necessary in order to allow testing of what appears to be a false positive for this action in Brakeman
      @master = Master.create_master_records current_user unless Rails.env.test? && params[:testfail] == 'testfail'
    end
    if @master && @master.id
      redirect_to master_path(@master.id), notice:  "Created Master Record with MSID #{@master.id}"
    else
      redirect_to new_master_url, notice: "Error creating Master Record: #{Application.record_error_message @master}"
    end
  end

private

  def init_vars
    instance_var_init :master
    instance_var_init :id
    instance_var_init :do_search
  end

  def search_params

    p = params_nil_if_blank params
    p = params_downcase p
    #p = p.permit(:master_id, player_info_attributes: [:first_name, :middle_name, :last_name, :nick_name, :birth_date, :death_date, :start_year], player_contacts_attributes: [], pro_info_attributes: [], address_attributes: [], manual_investigation_attributes: [])
    p = p.except(:utf8, :controller, :action).permit!
    logger.debug "Screened params: #{p.inspect}"
    p
  end

  def authorized?
    return true if current_user.can? :create_msid
    return not_authorized
  end

end
