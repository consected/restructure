class Master < ActiveRecord::Base

  ResultsLimit = 100

  MasterRank  = "master_rank desc nulls last, masters.id desc nulls last".freeze
  PlayerInfoRankOrderClause = "case when rank is null then -1000 when rank > #{PlayerInfo::BestAccuracyScore} then rank * -1 else rank end desc nulls last".freeze
  RankNotNullClause = ' case rank when null then -1 else rank * -1 end'.freeze
  TrackerEventOrderClause = 'protocols.position asc, event_date DESC NULLS last, trackers.updated_at DESC NULLS last '
  TrackerHistoryEventOrderClause = 'event_date DESC NULLS last, tracker_history.updated_at DESC NULLS last '
  # inverse_of required to ensure the current_user propagates between associated models correctly
  has_many :player_infos, -> { order(PlayerInfoRankOrderClause)  } , inverse_of: :master  
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

  before_create :assign_msid
    
  Master.reflect_on_all_associations(:has_many).each do |assoc| 
    # This association is provided to allow generic search on flagged associated object
    has_many "#{assoc.plural_name}_item_flags".to_sym, through: assoc.plural_name, source: :item_flags
    Rails.logger.debug "Associated master with #{assoc.plural_name}_item_flags through #{assoc.plural_name} with source :item_flags"
  end
  
  # Nested attributes for advanced search form
  accepts_nested_attributes_for :general_infos, :player_infos, :pro_infos, 
                                :scantrons, :player_contacts, :addresses, :trackers, :tracker_histories,
                                :not_trackers, :not_tracker_histories

  
  DefaultJoins = []
  # AltConditions allows certain search fields to be handled differently from a plain equality match
  # Simply define a hash for the table containing the symbolized field names to be handled
  # Use a hash with :value to define a predefined matching clause:
  # :starts_with is the equivalent of "?%"
  # :contains is the equivalent of "%?%" 
  # :is  and :is_not are the equivalent of "?"
  # :do_nothing forces this attribute to be skipped
  # Subsequent symbols in the array can be used to modify the string
  # :strip_spaces removes all spaces from the string
  # :upcase makes the whole string uppercase
  # The :conditioncan be specified to state the actual query condition
  # :starts with and :contains both default to "field_name LIKE ?"
  # :is_not default to "field_name <> ?"  
  # note that ? characters will be replaced by the field search value
  # Optionally add a value (symbol or array of symbols) for :joins
  # to specify specific tables to add to the inner join list
  
  AltConditions = {
    player_infos: {
      first_name: {value: :starts_with},
      middle_name: {value: :starts_with},
      nick_name: {value: :starts_with},
      notes: {value: :contains},
      younger_than: {value: :years, condition: "player_infos.birth_date is not null  AND ((current_date - interval ? )) < player_infos.birth_date"},
      older_than: {value: :years, condition: "player_infos.birth_date is not null  AND ((current_date - interval ?)) > player_infos.birth_date"},
      less_than_career_years: {value: :is, condition: "player_infos.start_year is not null AND player_infos.end_year IS NOT NULL  AND (player_infos.end_year - player_infos.start_year) < ?"},
      more_than_career_years: {value: :is, condition: "player_infos.start_year is not null AND player_infos.end_year IS NOT NULL  AND (player_infos.end_year - player_infos.start_year) > ?"}
    },
    pro_infos: {
      first_name: {value: :starts_with},
      middle_name: {value: :starts_with},
      nick_name: {value: :starts_with}
      
    },
    player_contacts: {
      data: {value: [:starts_with, :strip_spaces]}
    },
    not_trackers: {
      protocol_event_id: {value: :is, condition: "NOT EXISTS (select NULL from trackers t_inner where t_inner.protocol_event_id = ? AND t_inner.master_id = masters.id)"},
      sub_process_id: {value: :do_nothing}
    },
    not_tracker_histories: {
      protocol_event_id: {value: :is, condition: "NOT EXISTS (select NULL from tracker_history th_inner where th_inner.protocol_event_id = ? AND th_inner.master_id = masters.id)"},
      sub_process_id: {value: :do_nothing}
    },
    general_infos: {
      first_name: {value: :starts_with, condition: "(player_infos.first_name LIKE ? OR pro_infos.first_name LIKE ? OR player_infos.nick_name LIKE ? OR pro_infos.nick_name LIKE ?)", joins: :pro_infos},
      last_name: {value: :is, condition: "(player_infos.last_name = ? OR pro_infos.last_name = ?)", joins: :pro_infos},
      birth_date: {value: :is, condition: "(player_infos.birth_date = ? OR pro_infos.birth_date = ?)", joins: :pro_infos},
      death_date: {value: :is, condition: "(player_infos.death_date = ? OR pro_infos.death_date = ?)", joins: :pro_infos},
      start_year: {value: :is, condition: "(player_infos.start_year = ? OR pro_infos.start_year = ?)", joins: :pro_infos},
      end_year: {value: :is, condition: "(player_infos.end_year = ? OR pro_infos.end_year = ?)", joins: :pro_infos},
      college: {value: :is, condition: "(player_infos.college = ? OR pro_infos.college = ?)", joins: :pro_infos},
      contact_data: {value: [:starts_with, :strip_spaces], condition: "player_contacts.data LIKE ?", joins: :player_contacts }
    }
    
  }
  
  attr_accessor :force_order
  
  # Build a Master search using the Master and nested attributes passed in
  # Any attributes that are nil will be rejected and will not appear in the query
  # Tables will only be joined if the nested attributes for the association have one or more
  # attributes that are not nil
  def self.search_on_params params, conditions={}
    
    joins = DefaultJoins.dup # list of joined tables
    wheres = {} # set of equality where clauses
    wheresalt = [nil, {}] # list of non-equality where clauses (such as LIKE)
    selects = ["masters.id", "masters.pro_info_id", "masters.pro_id", "masters.msid", "masters.rank as master_rank"]
    
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
            logger.info "Merging alternative conditions"
            valt.each do |vset|
              if vset && vset[:condition]
                logger.info "Condition: #{vset[:condition]}"
                wheresalt[0] = "#{wheresalt[0]}#{wheresalt[0] ? " AND " : ''}#{vset[:condition]}"
                wheresalt[1].merge! vset[:reference]
                if vset[:joins].is_a? Symbol
                  joins << vset[:joins] 
                  logger.info "Adding alt join #{vset[:joins]}"
                elsif vset[:joins].is_a? Array
                  joins += vset[:joins] 
                  logger.info "Adding alt joins #{vset[:joins]}"
                end
              end
            end
          end
          #TODO fix this!
          joins << k1.to_sym        
          logger.info "adding standard join #{k1s.to_sym} when vn = #{vn}"
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
        
    
    res = Master.select(selects).joins(joins).uniq.where(wheres)
    res = res.where(wheresalt.first, wheresalt.last) if wheresalt.first
    
    default_sort res
    
  end

  def accuracy_rank
    pi = player_infos.first
    return -1000 unless pi
    pi.accuracy_rank
  end
  
  def self.default_sort res
    # Note that this sorts first, based on the Master rank, which is calculated through a trigger from player info accuracy
    res = res.order(MasterRank).take(ResultsLimit) 
    logger.info "sorted to #{res.map {|a| [a.id, a.master_rank]}  } "
    res        
  end
  
  def self.alt_condition table_name, condition    
    ckey = condition.first
    cval = condition.last
    
    return if !table_name || !condition || ckey.nil? || cval.nil?
    altable = AltConditions[table_name].dup
    return unless altable
    altdef = altable[ckey.to_sym]
    return unless altdef
    
    
    cond_op = altdef[:value]
    return if cond_op == :do_nothing
    
    refname = "#{table_name}_#{ckey}"
    
    
    if altdef[:condition]
      alt  = altdef[:condition]
    elsif cond_op == :starts_with || cond_op == :contains
      alt = "#{table_name}.#{ckey} LIKE ?"      
    elsif cond_op == :is_not
      alt = "#{table_name}.#{ckey} <> ?"
    end
    
    if altdef[:value].is_a? Array
      altdef[:value].each do |d|
        if d == :strip_spaces
          cval.gsub!(' ','')
        elsif d == :upcase
          cval.upcase!
        end
      end
    end
    
    alt = alt.gsub('?', ":#{refname}")
    
    cvaltotal = "#{cval}%" if cond_op == :starts_with
    cvaltotal = "%#{cval}%" if cond_op == :contains
    cvaltotal = cval if cond_op == :is
    cvaltotal = "#{cval} years" if cond_op == :years
    cvaltotal = "#{cval}" if cond_op == :is_not
    
    joins = altdef[:joins]
    
    res = {condition: alt, reference: {refname.to_sym => cvaltotal}, joins: joins}
      
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

  def assign_msid
    
    max_msid = Master.maximum(:msid) || 0
    self.msid = max_msid + 1
    
  end
  
end
