# frozen_string_literal: true

class MastersController < UserBaseController
  before_action :init_vars

  before_action :authorized?, only: %i[new create]

  include MasterSearch

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
    if params[:type] == 'msid' && params[:id]
      @master = Master.find_by_msid(params[:id])
      return not_found unless @master

      @msid = @master.msid
    elsif params[:id]
      @master = Master.find(params[:id])
      return not_found unless @master

      @master_id = @master.id
      @master.current_user = current_user
    end

    # Allow return of a simple JSON master
    respond_to do |format|
      format.html { search }
      format.json { render json: { master: @master } }
    end
  end

  def search
    @msid ||= params[:nav_q]
    @master_pro_id ||= params[:nav_q_pro_id]
    @master_id ||= params[:nav_q_id] unless app_config_text(:prevent_reload_master_list, nil)

    @requested_master = @master_id || @master_pro_id || @msid

    @master_req_format = params[:req_format] || 'reg'

    @master = Master.new

    # Advanced search fields
    @master.pro_infos.build
    @master.player_infos.build
    @master.addresses.build
    @master.player_contacts.build
    @master.trackers.build
    @master.tracker_histories.build
    @master.scantrons.build if defined? Scantron
    # @master.sage_assignments.build

    # NOT conditions
    @master.not_trackers.build
    @master.not_tracker_histories.build

    # Simple search fields
    @master.general_infos.build

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

    if @master&.id
      redirect_to master_path(@master.id), notice: "Created Master Record with MSID #{@master.id}"
    else
      redirect_to new_master_url, notice: "Error creating Master Record: #{Application.record_error_message @master}"
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
