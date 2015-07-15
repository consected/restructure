class Master < ActiveRecord::Base

  PlayerInfoRankOrderClause = ' case rank < 20 when true then rank * -1 else rank  end'.freeze
  RankNotNullClause = ' case rank when null then -1 else rank * -1 end'.freeze
  TrackerEventOrderClause = 'protocols.position asc, event_date DESC NULLS last, trackers.updated_at DESC NULLS last '
  TrackerHistoryEventOrderClause = 'event_date DESC NULLS last, tracker_history.updated_at DESC NULLS last '
  # inverse_of required to ensure the current_user propagates between associated models correctly
  has_many :player_infos, -> { order(PlayerInfoRankOrderClause)  } , inverse_of: :master
  has_many :manual_investigations  , inverse_of: :master
  has_many :pro_infos , inverse_of: :master  
  has_many :player_contacts, -> { order(RankNotNullClause)}, inverse_of: :master
  has_many :addresses, -> { order(RankNotNullClause)}  , inverse_of: :master
  has_many :trackers, -> { includes(:protocol).order(TrackerEventOrderClause)}, inverse_of: :master
  has_many :tracker_histories, -> { order(TrackerHistoryEventOrderClause)}, inverse_of: :master
  has_many :scantrons, -> { order(RankNotNullClause)}  , inverse_of: :master
  
  # This association is provided to allow 'simple' search on names in player_infos OR pro_infos 
  has_many :general_infos, class_name: 'PlayerInfo' 
  
  # Associations to allow advanced searches for NOT 
  has_many :not_tracker_histories, -> { order(TrackerHistoryEventOrderClause)},  class_name: 'TrackerHistory'
  has_many :not_trackers, -> { order(TrackerEventOrderClause)},  class_name: 'Tracker'

  
  Master.reflect_on_all_associations(:has_many).each do |assoc| 
    # This association is provided to allow generic search on flagged associated object
    has_many "#{assoc.plural_name}_item_flags".to_sym, through: assoc.plural_name, source: :item_flags
    Rails.logger.debug "Associated master with #{assoc.plural_name}_item_flags through #{assoc.plural_name} with source :item_flags"
  end
  
  # Nested attributes for advanced search form
  accepts_nested_attributes_for :general_infos, :player_infos, :pro_infos, :manual_investigations, 
                                :scantrons, :player_contacts, :addresses, :trackers, :tracker_histories,
                                :not_trackers, :not_tracker_histories

  # AltConditions allows certain search fields to be handled differently from a plain equality match
  # Simply define a hash for the table containing the symbolized field names to be handled
  # Use an array of a single item to define a predefined matching clause:
  # :starts_with is the equivalent of "?%"
  # :contains is the equivalent of "%?%" 
  # :is  and :is_not are the equivalent of "?"
  # any other string will be used as is 
  # note that ? characters will be replaced by the field search value
  # A second item in the array can be specified to state the actual query condition
  # :starts with and :contains both default to "field_name LIKE ?"
  # :is_not default to "field_name <> ?"
  AltConditions = {
    player_infos: {
      first_name: [:starts_with],
      middle_name: [:starts_with],
      nick_name: [:starts_with],
      notes: [:contains],
      younger_than: [:years, "player_infos.birth_date is not null  AND ((current_date - interval ? )) < player_infos.birth_date"],
      older_than: [:years, "player_infos.birth_date is not null  AND ((current_date - interval ?)) > player_infos.birth_date"],
      less_than_career_years: [:is, "player_infos.start_year is not null AND player_infos.end_year IS NOT NULL  AND (player_infos.end_year - player_infos.start_year) < ?"],
      more_than_career_years: [:is, "player_infos.start_year is not null AND player_infos.end_year IS NOT NULL  AND (player_infos.end_year - player_infos.start_year) > ?"]
    },
    pro_infos: {
      first_name: [:starts_with],
      middle_name: [:starts_with],
      nick_name: [:starts_with]
      
    },
    player_contacts: {
      data: [:starts_with]
    },
    not_trackers: {
      protocol_event_id: [:is, "NOT EXISTS (select NULL from trackers t_inner where t_inner.protocol_event_id = ? AND t_inner.master_id = masters.id)"],
      sub_process_id: [:do_nothing]
    },
    not_tracker_histories: {
      protocol_event_id: [:is, "NOT EXISTS (select NULL from tracker_history th_inner where th_inner.protocol_event_id = ? AND th_inner.master_id = masters.id)"],
      sub_process_id: [:do_nothing]
    }
#    # This was a test. Not working.
#    not_player_infos_item_flags: {
#      item_flag_name_id: [:is, "NOT EXISTS (select NULL from item_flags if_inner where if_inner.item_flag_name_id IN (?) AND if_inner.item_id = player_infos.id AND if_inner.item_type = 'PlayerInfo')"]
#    },
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
          logger.debug "Reflection: #{r.klass.table_name}"
          if r.klass #r.source_reflection
            k1s =  r.klass.table_name #r.source_reflection.name.to_s
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
    
    joins  = [:player_infos, "left outer join pro_infos on pro_infos.master_id = masters.id"]
    p.each do |k,v|
      unless v.nil?
        w << " AND " unless first
                
        if k == 'contact_data'
          w << "player_contacts.data LIKE :#{k}"      
          wcond[k.to_sym] = "#{v}%"
          joins << [:player_contacts]
        elsif k == 'first_name'   
          w << "(player_infos.#{k} LIKE :#{k} OR pro_infos.#{k} LIKE :#{k} OR player_infos.nick_name LIKE :#{k} OR pro_infos.nick_name LIKE :#{k})"      
          wcond[k.to_sym] = "#{v}%"
        else
          w << "(player_infos.#{k} = :#{k} OR pro_infos.#{k} = :#{k})"      
          wcond[k.to_sym] = v
        end  
        
        
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
    
    
    cop = altpair[0]
    return if cop == :do_nothing
    refname = "#{table_name}_#{ckey}"
    
    if altpair[1]
      alt  = altpair[1]
    elsif cop == :starts_with || cop == :contains
      alt = "#{table_name}.#{ckey} LIKE ?"      
    elsif cop == :is_not
      alt = "#{table_name}.#{ckey} <> ?"
    end
    
    alt = alt.gsub('?', ":#{refname}")
    
    cvaltotal = "#{cval}%" if cop == :starts_with
    cvaltotal = "%#{cval}%" if cop == :contains
    cvaltotal = cval if cop == :is
    cvaltotal = "#{cval} years" if cop == :years
    cvaltotal = "#{cval}" if cop == :is_not
    
    res = [alt, {refname.to_sym => cvaltotal}]
      
    res
  end
  
  

  def current_user= cu
    logger.info "Setting current user: #{cu} in #{self}"
    @user_id = cu
  end
  
  def current_user
    logger.info "Getting current user: #{@user_id} from #{self}"
    @user_id
  end
  
private

  
end
