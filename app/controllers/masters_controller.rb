class MastersController < ApplicationController
  before_action :authenticate_user!
  
  
  ResultsLimit = 100
  
  def index
    #search_params
    redirect_to '/masters/search/' and return if search_params.nil? || search_params.length == 0
    
    search_type = params[:mode] 
    search_type = 'ADVANCED' if search_type.blank?
    
    if search_type == 'MSID'
      if !params[:master][:id].blank?
      @masters = Master.where id: params[:master][:id] 
      elsif !params[:master][:pro_infos_attributes]["0"][:pro_id].blank?
      @masters = Master.where id: params[:master][:pro_id]
      end
    elsif search_type == 'SIMPLE'
      @masters = Master.simple_search_on_params search_params[:master]
    else
      @masters = Master.search_on_params search_params[:master]
    end

    if @masters
    
      @masters = @masters.take(ResultsLimit).sort {|m,n| (n.player_infos.first.accuracy_rank || -2) <=> (m.player_infos.first.accuracy_rank || -2)}

      m = {
        masters: @masters.as_json(include: {
          player_infos: {order: Master::PlayerInfoRankOrderClause, 
            include: {
              pro_info: {}, 
              item_flags: {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
            },
            methods: [:user_name, :accuracy_score_name]
          },
          player_contacts: {
            order: {rank: :desc},             
            methods: [:user_name]
          },
          addresses: {
            order: {rank: :desc},             
            methods: [:user_name]
          },
          trackers: {
            order: "protocol.position #{Master::TrackerEventOrderClause}",  
            methods: [:protocol_name, :protocol_position, :sub_process_name, :event_name, :tracker_history_length, :user_name]
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
      m = {message: "no conditions were specified"}
      log_action "master search", search_type, 0, "no conditions specified"
    end

    render json: m
    
  end

  def show
    @master = Master.find(params[:id])
    @master_id = @master.id
    
    search
    
  end
  
  def search
    @master_id ||= params[:nav_q]
    @master_pro_id ||= params[:nav_q_pro_id]
    
    @master =  Master.new 
    
    # Advanced search fields
    @master.pro_infos.build
    @master.player_infos.build
    @master.manual_investigations.build
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
  end
  
  def create
    @master = Master.create
    
    redirect_to @master, notice:  "Created Master Record with MSID #{@master.id}"
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
