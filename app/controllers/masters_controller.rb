class MastersController < ApplicationController
  before_action :authenticate_user!
  
  
  ResultsLimit = 10
  
  def index
    #search_params
    redirect_to '/masters/search/' and return if search_params.nil? || search_params.length == 0
    
    if params[:mode] == 'SIMPLE'
      @masters = Master.simple_search_on_params search_params[:master] 
    else
      @masters = Master.search_on_params search_params[:master] 
    end
    
    @masters.take(ResultsLimit)
    
    m = {
      masters: @masters.as_json(include: {
        player_infos: {order: {rank: :desc}, include: :pro_info},
        player_contacts: {order: {rank: :desc}},
        manual_investigations: {order: {rank: :desc}},
        addresses: {order: {rank: :desc}},
        trackers: {order: {created_at: :desc}, methods: :protocol_name},
        scantrons: {order: {scantron_id: :asc}}
      }) 
    }

    render json: m
    
  end

  def show
    @master = Master.find(params[:id])
    @master_id = @master.id
    
    search
    
  end
  
  def search
    @master_id ||= params[:nav_q]
    
    @master =  Master.new 
    
    # Advanced search fields
    @master.pro_infos.build
    @master.player_infos.build
    @master.manual_investigations.build
    @master.addresses.build
    @master.player_contacts.build
    
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
    
    p
  end
  
  
end
