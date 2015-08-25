class Master < ActiveRecord::Base

  ResultsLimit = 100

  MasterRank  = "master_rank desc nulls last, masters.id desc nulls last".freeze
  PlayerInfoRankOrderClause = "case when rank is null then -1000 when rank > #{PlayerInfo::BestAccuracyScore} then rank * -1 else rank end desc nulls last".freeze
  RankNotNullClause = ' case rank when null then -1 else rank * -1 end'.freeze
  TrackerEventOrderClause = 'protocols.position asc, event_date DESC NULLS last, trackers.updated_at DESC NULLS last '
  TrackerHistoryEventOrderClause = 'event_date DESC NULLS last, tracker_history.updated_at DESC NULLS last '
  
  belongs_to :user
  
  # inverse_of required to ensure the current_user propagates between associated models correctly
  has_many :player_infos, -> { order(PlayerInfoRankOrderClause)  } , inverse_of: :master  
  has_many :pro_infos , inverse_of: :master  
  has_many :player_contacts, -> { order(RankNotNullClause)}, inverse_of: :master
  has_many :addresses, -> { order(RankNotNullClause)}  , inverse_of: :master
  has_many :trackers, -> { includes(:protocol).order(TrackerEventOrderClause)}, inverse_of: :master
  has_many :tracker_histories, -> { order(TrackerHistoryEventOrderClause)}, inverse_of: :master
  has_many :scantrons, -> { order(RankNotNullClause)}  , inverse_of: :master
  has_many :latest_tracker_history, -> { order(id: :desc).limit(1)},  class_name: 'TrackerHistory'
  
  # This association is provided to allow 'simple' search on names in player_infos OR pro_infos 
  has_many :general_infos, class_name: 'ProInfo' 
  
  # Associations to allow advanced searches for NOT 
  has_many :not_tracker_histories, -> { order(TrackerHistoryEventOrderClause)},  class_name: 'TrackerHistory'
  has_many :not_trackers, -> { order(TrackerEventOrderClause)},  class_name: 'Tracker'

  before_validation :set_user
  before_validation :prevent_user_updates,  on: :update
  validates :user, presence: true  
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

  
  
  SimplePlayerJoin = "LEFT JOIN player_infos on masters.id = player_infos.master_id LEFT JOIN pro_infos as pro_infos on masters.id = pro_infos.master_id".freeze
  NotTrackerJoin = :no_join #'INNER JOIN trackers "not_trackers" on masters.id = not_trackers.master_id'
  NotTrackerHistoryJoin = :no_join #'INNER JOIN tracker_history "not_tracker_histories" on masters.id = not_tracker_histories.master_id'
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
  # Optionally add a value (symbol or array of symbols or string specifying full join clause) for :joins
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
    addresses: {
      street: {value: :starts_with},
      zip: {value: :starts_with}
    },
    player_contacts: {
      data: {value: [:starts_with, :strip_non_alpha_numeric], condition: "regexp_replace(player_contacts.data, '\\W+', '', 'g') LIKE ?"}
    },
    not_trackers: {
      protocol_event_id: {value: :is, condition: "NOT EXISTS (select NULL from trackers t_inner where t_inner.protocol_event_id = ? AND t_inner.master_id = masters.id)", joins: NotTrackerJoin},
      sub_process_id: {value: :do_nothing}      
    },
    not_tracker_histories: {
      protocol_event_id: {value: :is, condition: "NOT EXISTS (select NULL from tracker_history th_inner where th_inner.protocol_event_id = ? AND th_inner.master_id = masters.id)", joins: NotTrackerHistoryJoin},
      sub_process_id: {value: :do_nothing}
    },
    general_infos: {
      first_name: {value: :starts_with, condition: "(player_infos.first_name LIKE ? OR pro_infos.first_name LIKE ? OR player_infos.nick_name LIKE ? OR pro_infos.nick_name LIKE ?)", joins: SimplePlayerJoin},
      last_name: {value: :is, condition: "(player_infos.last_name = ? OR pro_infos.last_name = ?)", joins: SimplePlayerJoin},
      birth_date: {value: :is, condition: "(player_infos.birth_date = ? OR pro_infos.birth_date = ?)", joins: SimplePlayerJoin},
      death_date: {value: :is, condition: "(player_infos.death_date = ? OR pro_infos.death_date = ?)", joins: SimplePlayerJoin},
      start_year: {value: :is, condition: "(player_infos.start_year = ? OR pro_infos.start_year = ?)", joins: SimplePlayerJoin},
      end_year: {value: :is, condition: "(player_infos.end_year = ? OR pro_infos.end_year = ?)", joins: SimplePlayerJoin},
      college: {value: :is, condition: "(player_infos.college = ? OR pro_infos.college = ?)", joins: SimplePlayerJoin},
      contact_data: {value: [:starts_with, :strip_non_alpha_numeric], condition: "regexp_replace(player_contacts.data, '\\W+', '', 'g') LIKE ?", joins: :player_contacts}
    }
    
  }
  
  # Don't automatically generate a join for specific AltConditions
  # This allows for a :joins definition in AltConditions to define a LEFT OUTER JOIN on the primary table, for example
  NoDefaultJoinFor = [:general_infos, :not_trackers, :not_tracker_histories ]
  
  attr_accessor :force_order
  
  # Build a Master search using the Master and nested attributes passed in
  # Any attributes that are nil will be rejected and will not appear in the query
  # Tables will only be joined if the nested attributes for the association have one or more
  # attributes that are not nil
  def self.search_on_params params, conditions={}
    
    joins = [] # list of joined tables
    wheres = {} # set of equality where clauses
    wheresalt = [nil, {}] # list of non-equality where clauses (such as LIKE)
    selects = ["masters.id", "masters.pro_info_id", "masters.pro_id", "masters.msid", "masters.rank as master_rank"]
    
    params.each do |params_key,params_val|
      
      if params_val.is_a? Hash
        
        if params_val.first.first == "0"
          # Grab the first array item from the parameters if there is one to reset the context
          params_val = params_val.first.last
        end
        
        # Handle nested attributes
        # Get the key name for the table by removing the _attributes extension from the key
        
        if params_key.to_s.include? '_attributes'
          condition_key = params_key.to_s.gsub('_attributes','').to_sym
          r = Master.reflect_on_association(condition_key)
          logger.debug "condition_key: #{condition_key}"
          logger.debug "Reflection: #{r.klass.table_name}"
          logger.debug "Source Reflection: #{r.source_reflection.name && r.source_reflection.name}"          
          if r.klass #r.source_reflection # 
            condition_table =  r.klass.table_name #r.source_reflection.name.to_s #
          else
            condition_table = r.plural_name.to_s
          end
          
        else
          # Generate a pluralized table name for associations that are has_one
          condition_table = params_key.to_s.pluralize
        end
        
        # Keep only non-nil attributes for the primary wheres that don't have an alternative condition string
        
        basic_condition_attribs = params_val.select{|key1,v1| !v1.nil? && !alt_condition(condition_key, [key1, v1])}
        
        # Pull the attributes with an alternative condition string (note that this returns nil values too)
        # format: {condition: condition_clause, reference: {reference_name => value}, joins: joins_clauses} 
        alt_condition_attribs = params_val.select{|_,v1| !v1.nil? }.map{|v2| alt_condition(condition_key, v2) }
        
        logger.debug "Param: #{params_key} has condition_table: #{condition_table}"
        logger.debug "basic_condition_attribs #{basic_condition_attribs} -- alt_condition_attribs #{alt_condition_attribs}"
        
        # If we have a set of attributes that is not empty 
        # add the equality conditions to the list of wheres
        if basic_condition_attribs.length > 0 || alt_condition_attribs.length > 0
          
          # When this is a basic condition
          if basic_condition_attribs.length > 0            
            logger.debug "This is a basic condition for condition_table #{condition_table}"
            # When the where for the condition_table is an array of key/values already, just add to it
            # otherwise store the basic condition attributes directly
            if wheres[condition_table] && wheres[condition_table].first.last.is_a?(Array)              
              wheres[condition_table][basic_condition_attribs.first.first] += basic_condition_attribs.first.last 
            else              
              wheres[condition_table] = basic_condition_attribs 
            end
          end
          # When there is a defined alternative condition
          if alt_condition_attribs.length > 0          
            logger.info "Merging alternative conditions FOR #{alt_condition_attribs}"
            # For each alternative condition attribute, check if it has a defined condition, then
            # generate alternative where clauses
            alt_condition_attribs.each do |alt_condition_attrib|
              if alt_condition_attrib && alt_condition_attrib[:condition]
                logger.info "Alt Condition: #{alt_condition_attrib[:condition]}"
                wheresalt[0] = "#{wheresalt[0]}#{wheresalt[0] ? " AND " : ''}#{alt_condition_attrib[:condition]}"
                wheresalt[1].merge! alt_condition_attrib[:reference]
                if alt_condition_attrib[:joins].is_a?(Symbol) && alt_condition_attrib[:joins] != :no_join
                  joins << alt_condition_attrib[:joins] 
                  logger.info "Adding alt join #{alt_condition_attrib[:joins]}"
                elsif alt_condition_attrib[:joins].is_a? String
                  joins << alt_condition_attrib[:joins] 
                  logger.info "Adding alt joins #{alt_condition_attrib[:joins]}"
                elsif alt_condition_attrib[:joins].is_a? Array
                  joins += alt_condition_attrib[:joins] 
                  logger.info "Adding alt joins #{alt_condition_attrib[:joins]}"
                else
                  logger.info "Not Adding alt joins"
                end
              end
            end
          end
          
          logger.debug "Adding condition_key to joins: #{condition_key}"
          joins << condition_key unless NoDefaultJoinFor.include?(condition_key)
          logger.info "adding standard join params_val=#{condition_table.to_sym} when basic_condition_attribs = #{basic_condition_attribs}"
          conditions[condition_key] = basic_condition_attribs
        end
        # Always add the table to the list of joins and select (so we can get the data)
        
      elsif !params_val.nil?
        # Handle Master level attributes
        wheres[params_key] = params_val
      end
      
    end
        
    
    # No conditions were recognized. Exit now.
    return nil if wheres.length == 0 && !wheresalt.first
        
    logger.debug "joins: #{joins}"
    logger.debug "Standard wheres: #{wheres}"
    logger.debug "Alt wheres: #{wheresalt}"
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
    
    logger.debug "Getting alt_condition for #{table_name} => #{condition}"
    
    ckey = condition.first
    cval = condition.last
    
    return if !table_name || !condition || ckey.nil? || cval.nil?
    altable = AltConditions[table_name]
    return unless altable
    altable = altable.dup
    altdef = altable[ckey.to_sym]
    return unless altdef
    altdef = altdef.dup
    
    
    cond_op = altdef[:value]
    return {} if cond_op == :do_nothing
    
    cond_op = [cond_op] unless cond_op.is_a? Array
    
    refname = "#{table_name}_#{ckey}"
    
    
    if altdef[:condition]
      alt  = altdef[:condition]
    elsif cond_op.include?(:starts_with) || cond_op.include?(:contains)
      alt = "#{table_name}.#{ckey} LIKE ?"      
    elsif cond_op.include?(:is_not)
      alt = "#{table_name}.#{ckey} <> ?"
    else
      alt = "#{table_name}.#{ckey} = ?"
    end
    
    if altdef[:value].is_a? Array
      altdef[:value].each do |d|
        if d == :strip_spaces
          cval.gsub!(' ','')
        elsif d == :strip_non_alpha_numeric
          cval.gsub!(/\W+/,'')
        elsif d == :upcase
          cval.upcase!
        end
      end
    end
    
    alt = alt.gsub('?', ":#{refname}")
    
    cvaltotal = "#{cval}%" if cond_op.include? :starts_with
    cvaltotal = "%#{cval}%" if cond_op.include? :contains
    cvaltotal = cval if cond_op.include? :is
    cvaltotal = "#{cval} years" if cond_op.include? :years
    cvaltotal = "#{cval}" if cond_op.include? :is_not
    
    joins = altdef[:joins]
    
    res = {condition: alt, reference: {refname.to_sym => cvaltotal}, joins: joins}
      
    res
  end
  
  # Current admin is not stored, but may be used in validations for administrative level changes
  def current_admin=ca
    @current_admin = ca.is_a?(Admin)
  end
  
  def is_admin?
    !!@current_admin
  end

  def current_user= cu
    
    if cu.is_a? User
      @current_user = cu
    elsif cu.is_a? Integer
      @current_user = User.find cu
    else 
      raise "Attempting to set current_user with non user: #{cu}"
    end    
  end
  
  def current_user
    logger.info "Getting current user: #{@user_id} from #{self}"
    # Do not get the user association when requesting the current_user, since we 
    # do not want the value that has been persisted in the data
    @current_user
  end
  
  # Prevent user from being set directly, to avoid accidental or malicious changes to the recorded user in records
  def user= u
    raise "can not set user="
  end
  
  def user_id= u
    raise "can not set user_id="
  end
  
  def self.create_master_records user
    
    raise "no user specified" unless user
    
    m = Master.create!(current_user: user)
    m.player_infos.create!
    return m
    
  end
  
private

  def assign_msid
    
    max_msid = Master.maximum(:msid) || 0
    self.msid = max_msid + 1
    
  end

  def prevent_user_updates
    errors.add :pro_id, "can not be updated by users" if pro_id_changed?
    errors.add :msid, "can not be updated by users" if msid_changed?
    errors.add "pro info association", "can not be updated by users" if pro_info_id_changed?
  end

  def set_user
    cu = @current_user
    # Set the user association when current_user is set
    if cu.is_a?(User) && cu.persisted?
      write_attribute :user_id, cu.id
    else 
      raise "Attempting to set user with non user: #{cu}"
    end
    
  end
  
end
