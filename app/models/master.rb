class Master < ActiveRecord::Base

  PlayerInfoRankOrderClause = ' case rank < 20 when true then rank * -1 else rank  end'.freeze
  RankNotNullClause = ' case rank when null then -1 else rank * -1 end'.freeze
  # inverse_of required to ensure the current_user propagates between associated models correctly
  has_many :player_infos, -> { order(PlayerInfoRankOrderClause)  } , inverse_of: :master
  has_many :manual_investigations  , inverse_of: :master
  has_many :pro_infos , inverse_of: :master  
  has_many :player_contacts, -> { order(RankNotNullClause)}, inverse_of: :master
  has_many :addresses, -> { order(RankNotNullClause)}  , inverse_of: :master
  has_many :trackers  , inverse_of: :master
  has_many :scantrons, -> { order(RankNotNullClause)}  , inverse_of: :master
  
  # This association is provided to allow 'simple' search on names in player_infos OR pro_infos 
  has_many :general_infos, class_name: 'PlayerInfo' 
  
  # TODO - make this real!
  has_one :address, -> { order(RankNotNullClause).limit(1)  } 
  
  
  accepts_nested_attributes_for :general_infos, :player_infos, :pro_infos, :manual_investigations, :player_contacts, :address, :addresses, :trackers
  
  # Build a Master search using the Master and nested attributes passed in
  # Any attributes that are nil will be rejected and will not appear in the query
  # Tables will only be joined if the nested attributes for the association have one or more
  # attributes that are not nil
  def self.search_on_params params
    
    joins = []
    wheres = {}
    selects = []
    
    params.each do |k,v|
      
      if v.is_a? Hash
        
        if v.first.first == "0"
          # Grab the first array item from the parameters if there is one to reset the context
          v = v.first.last
        end
        
        # Handle nested attributes
        # Get the key name for the table by removing the _attributes extension from the key
        k1 = k.to_s.gsub('_attributes','')
        # Generate a pluralized table name for associations that are has_one
        k1s = k1.pluralize
        # Keep only non-nil attributes
        vn = v.select {|_,v1| !v1.nil?}
        # If we have a set of attributes that is not empty 
        # add the equality conditions to the list of wheres
        if vn.length > 0
          wheres[k1s] = vn
          joins << k1.to_sym        
        end
        # Always add the table to the list of joins and select (so we can get the data)
        
      elsif !v.nil?
        # Handle Master level attributes
        wheres[k] = v
      end
      
    end
    
    Master.select(selects).joins(joins).uniq.where(wheres)
    
  end
  
  
  def self.simple_search_on_params params
    logger.info "Search Simple with #{params}"
    w = ""
    wcond = {}
    joins = []
    
    p = params[:general_infos_attributes]['0']
    first = true
    
    if params[:id]
      first = false
      w << "masters.id = :id"
      wcond[:id] =  params[:id].to_i
    end
    
    p.each do |k,v|
      unless v.nil?
        w << " AND " unless first
        w << "(player_infos.#{k} = :#{k} OR pro_infos.#{k} = :#{k})"      
        wcond[k.to_sym] = v
        joins  = [:player_infos, "left outer join pro_infos on pro_infos.master_id = masters.id"]
        first = false
      end
    end
    logger.info "where: #{w}, #{wcond}"
    Master.joins(joins).uniq.where(w, wcond)
  end
  
  
#  def as_json options=nil
#    
#    {
#      id: id, 
#      player_infos: player_infos.order(rank: :desc),
#      #pro_infos: pros,
#      player_contacts: player_contacts.order(rank: :desc), 
#      manual_investigations: manual_investigations(rank: :desc), 
#      addresses: addresses.order(rank: :desc)      
#    }
#    
#  end

  def current_user= cu
    logger.info "Setting current user: #{cu} in #{self}"
    @user_id = cu
  end
  
  def current_user
    @user_id
  end
  
private

  
end
