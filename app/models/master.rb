class Master < ActiveRecord::Base

  PlayerInfoRankOrderClause = ' case rank < 20 when true then rank * -1 else rank  end'.freeze
  RankNotNullClause = ' case rank when null then -1 else rank * -1 end'.freeze
  OutcomeEventDatesNotNullClause = 'outcome_date DESC NULLS last, event_date DESC NULLS last'
  # inverse_of required to ensure the current_user propagates between associated models correctly
  has_many :player_infos, -> { order(PlayerInfoRankOrderClause)  } , inverse_of: :master
  has_many :manual_investigations  , inverse_of: :master
  has_many :pro_infos , inverse_of: :master  
  has_many :player_contacts, -> { order(RankNotNullClause)}, inverse_of: :master
  has_many :addresses, -> { order(RankNotNullClause)}  , inverse_of: :master
  has_many :trackers, -> { order(OutcomeEventDatesNotNullClause)}, inverse_of: :master
  has_many :tracker_histories, -> { order(OutcomeEventDatesNotNullClause)}, inverse_of: :master
  has_many :scantrons, -> { order(RankNotNullClause)}  , inverse_of: :master
  
  # This association is provided to allow 'simple' search on names in player_infos OR pro_infos 
  has_many :general_infos, class_name: 'PlayerInfo' 
  
  Master.reflect_on_all_associations(:has_many).each do |assoc| 
    # This association is provided to allow generic search on flagged associated object
    has_many "#{assoc.plural_name}_item_flags".to_sym, through: assoc.plural_name, source: :item_flags
  end
    
  
  accepts_nested_attributes_for :general_infos, :player_infos, :pro_infos, :manual_investigations, :player_contacts, :addresses, :trackers
  
  AltConditions = {
    player_infos: {
      first_name: ['player_infos.first_name LIKE ?', :starts_with],
      nick_name: ['player_infos.nick_name LIKE ?', :starts_with],
      notes: ['player_infos.notes LIKE ?', :contains]
    },
    pro_infos: {
      first_name: ['pro_infos.first_name LIKE ?', :starts_with],
      nick_name: ['pro_infos.nick_name LIKE ?', :starts_with]
      
      }    
  }
  
  
  # Build a Master search using the Master and nested attributes passed in
  # Any attributes that are nil will be rejected and will not appear in the query
  # Tables will only be joined if the nested attributes for the association have one or more
  # attributes that are not nil
  def self.search_on_params params, conditions={}
    
    joins = [] # list of joined tables
    wheres = {} # set of equality where clauses
    wheresalt = [nil, {}] # list of non-equality where clauses (such as LIKE)
    selects = []
    
    params.each do |k,v|
      
      if v.is_a? Hash
        
        if v.first.first == "0"
          # Grab the first array item from the parameters if there is one to reset the context
          v = v.first.last
        end
        
        # Handle nested attributes
        # Get the key name for the table by removing the _attributes extension from the key
        
        if k.to_s.include? '_attributes'
          k1 = k.to_s.gsub('_attributes','')
          r = Master.reflect_on_association(k1.to_sym)
          
          if r.source_reflection
            k1s =  r.source_reflection.name.to_s
          else
            k1s = r.plural_name.to_s
          end
          
        else
          # Generate a pluralized table name for associations that are has_one
          k1s = k.to_s.pluralize
        end
        # Keep only non-nil attributes for the primary wheres that don't have an alternative condition string
        vn = v.select{|key1,v1| !v1.nil? && !alt_condition(k1.to_sym, [key1, v1])}
        
        # Pull the attributes with an alternative condition string (note that this returns nil values too)
        valt = v.select{|_,v1| !v1.nil? }.map{|v2| alt_condition(k1.to_sym, v2) }
        
        # If we have a set of attributes that is not empty 
        # add the equality conditions to the list of wheres
        if vn.length > 0 || valt.length > 0
          if vn.length > 0
            logger.info "vn(#{vn.first}, #{vn.first.last}): #{vn.inspect} -- #{wheres[k1s]}"
            if wheres[k1s] && wheres[k1s].first.last.is_a?(Array)
              logger.info "its an array" 
              wheres[k1s][vn.first.first] += vn.first.last 
            else
              wheres[k1s] = vn 
            end
          end
          if valt.length > 0
            valt.each do |cond, vals|
              if cond && !vals.nil?
                wheresalt[0] = "#{wheresalt[0]}#{wheresalt[0] ? " AND " : ''}#{cond}"
                wheresalt[1].merge! vals
              end
            end            
          end
          joins << k1.to_sym        
          
          conditions[k1.to_sym] = vn
        end
        # Always add the table to the list of joins and select (so we can get the data)
        
      elsif !v.nil?
        # Handle Master level attributes
        wheres[k] = v
      end
      
    end
    
    logger.info "Join: #{joins}\nWhere: #{wheres.inspect} << #{wheresalt.inspect} "
    
    # No conditions were recognized. Exit now.
    return nil if wheres.length == 0 && !wheresalt.first
    
    joins << :player_infos unless joins.include? :player_infos
    res = Master.select(selects).joins(joins).uniq.where(wheres)
    res = res.where(wheresalt.first, wheresalt.last) if wheresalt.first
    
    res
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
        if k == 'first_name'  || k == 'nick_name'
          w << "(player_infos.#{k} LIKE :#{k} OR pro_infos.#{k} LIKE :#{k})"      
          wcond[k.to_sym] = "#{v}%"
        else
          w << "(player_infos.#{k} = :#{k} OR pro_infos.#{k} = :#{k})"      
          wcond[k.to_sym] = v
        end  
        
        joins  = [:player_infos, "left outer join pro_infos on pro_infos.master_id = masters.id"]
        first = false
      end
    end
    logger.info "where: #{w}, #{wcond}"
    joins << :player_infos unless joins.include? :player_infos
    
    # No conditions were recognized. Exit now.
    return nil if wcond.length == 0
    
    Master.joins(joins).uniq.where(w, wcond)
  end
  
  def self.alt_condition table_name, condition    
    ckey = condition.first
    cval = condition.last
    
    return if !table_name || !condition || ckey.nil? || cval.nil?
    altable = AltConditions[table_name]
    return unless altable
    altpair = altable[ckey.to_sym]
    return unless altpair
    
    alt = altpair[0]
    cop = altpair[1]
    
    refname = "#{table_name}_#{ckey}"
    alt = alt.gsub('?', ":#{refname}")
    cvaltotal = "#{cval}%" if cop == :starts_with
    cvaltotal = "%#{cval}%" if cop == :contains
    res = [alt, {refname.to_sym => cvaltotal}]
    logger.debug "Checking for alt_condition:= #{res}"
    res
  end
  
  

  def current_user= cu
    logger.info "Setting current user: #{cu} in #{self}"
    @user_id = cu
  end
  
  def current_user
    @user_id
  end
  
private

  
end
