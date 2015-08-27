class MastersController < ApplicationController
  before_action :authenticate_user!
  
  
  ResultsLimit = Master::ResultsLimit
  
  def index
    
    #search_params
    redirect_to '/masters/search/' and return if search_params.nil? || search_params.length == 0
    
    search_type = params[:mode] 
    search_type = 'ADVANCED' if search_type.blank?
    msid = nil
    
    begin

      if search_type == 'MSID'
        if !params[:master][:msid].blank?
          msid = params[:master][:msid] 
          msid = msid.split(/[,| ]/) if msid.index(/[,| ]/)        
          @masters = Master.where msid: msid
        elsif !params[:master][:pro_id].blank?
          @masters = Master.where pro_id: params[:master][:pro_id]
        elsif !params[:master][:id].blank?
          @masters = Master.where id: params[:master][:id]
        end
      elsif search_type == 'SIMPLE'
        @masters = Master.search_on_params search_params[:master]
      else
        @masters = Master.search_on_params search_params[:master]
      end
    
      if @masters

        #If the msid is an array of items then return the results in the order of the list
        if msid.is_a? Array
          i = 0
          @masters = @masters.take(ResultsLimit)
          msid.each do |d|
            m1 = @masters.select {|n| n.msid.to_s == d}.first
            m1.force_order = i if m1
            i += 1
          end

          @masters = @masters.sort {|m,n| m.force_order <=> n.force_order}              
        end
        m = {
          masters: @masters.as_json(include: {
            player_infos: {order: Master::PlayerInfoRankOrderClause, 
              include: {              
                item_flags: {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
              },
              methods: [:user_name, :accuracy_score_name, :source_name]
            },
            pro_infos: {}, 
            player_contacts: {
              order: {rank: :desc},             
              methods: [:user_name, :rank_name, :source_name]
            },
            addresses: {
              order: {rank: :desc},             
              methods: [:user_name, :rank_name, :state_name, :country_name, :source_name]
            },
            trackers: {
              order: "protocol.position #{Master::TrackerEventOrderClause}",  
              methods: [:protocol_name, :protocol_position, :sub_process_name, :event_name, :tracker_history_length, :user_name, :record_type_us, :record_type, :record_id]
            },
            latest_tracker_history: {            
              methods: [:protocol_name, :protocol_position, :sub_process_name, :event_name, :user_name, :record_type_us, :record_type, :record_id, :event_description, :event_milestone]
            },
            scantrons: {
              order: {scantron_id: :asc},
              methods: [:user_name]
            }
          }) 
        }

        m[:count] = @masters.length

        log_action "master search", search_type, @masters.length
      else
        # Return no results      
        m = {message: "no conditions were specified", masters: [], count: 0}
        log_action "master search", search_type, 0, "no conditions specified"
      end
    rescue => e
      logger.error "Error in MastersController#index: #{e.inspect}\n#{e.backtrace.join("\n")}"
      m = {error: ": unable to search - please check your search criteria"}
      render json: m, status: 400
      return
    end

    render json: m
    
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
    
    @master =  Master.new 
    
    # Advanced search fields
    @master.pro_infos.build
    @master.player_infos.build
    @master.addresses.build
    @master.player_contacts.build
    @master.trackers.build
    @master.tracker_histories.build
    @master.scantrons.build
    
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
    # Unfortunately there is no easy way to force the create request to fail for the purposes of testing
    # Therefore we provide a way to force an apparent failure in the test environment.
    # This is necessary in order to allow testing of what appears to be a false positive for this action in Brakeman
    @master = Master.create_master_records current_user unless Rails.env.test? && params[:testfail] == 'testfail'
    if @master && @master.id
      redirect_to @master, notice:  "Created Master Record with MSID #{@master.id}"
    else
      redirect_to new_master_url, notice: "Error creating Master Record: #{Application.record_error_message @master}" 
    end
  end
  
private

  def search_params
    
    p = params_nil_if_blank params
    p = params_downcase p
    #p = p.permit(:master_id, player_info_attributes: [:first_name, :middle_name, :last_name, :nick_name, :birth_date, :death_date, :start_year], player_contacts_attributes: [], pro_info_attributes: [], address_attributes: [], manual_investigation_attributes: [])
    p = p.except(:utf8, :controller, :action).permit!
    logger.debug "Screened params: #{p.inspect}"
    p
  end
  
  
end
