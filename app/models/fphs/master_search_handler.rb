# frozen_string_literal: true

# Supporting functionality for the FPHS Simple and Advanced Search forms
# Although not ideal to just push this into a Concern, it does allow
# the Master model data functionality to remain obvious by simply adding and overriding
module Fphs
  module MasterSearchHandler
    extend ActiveSupport::Concern

    MasterRank = Arel.sql 'master_rank desc nulls last, masters.id desc nulls last'
    PlayerInfoRankOrderClause = Arel.sql 'case when rank is null then -1000 ' \
                                         "when rank > #{PlayerInfo::BestAccuracyScore} then rank * -1 " \
                                         'else rank end desc nulls last'
    RankNotNullClause = Arel.sql ' case rank when null then -1 else rank * -1 end'

    SimplePlayerJoin = Arel.sql 'LEFT JOIN player_infos on masters.id = player_infos.master_id LEFT JOIN pro_infos as pro_infos on masters.id = pro_infos.master_id'
    NotTrackerJoin = :no_join # 'INNER JOIN trackers "not_trackers" on masters.id = not_trackers.master_id'
    NotTrackerHistoryJoin = :no_join # 'INNER JOIN tracker_history "not_tracker_histories" on masters.id = not_tracker_histories.master_id'

    #
    # AltConditions allows certain search fields to be handled differently from a plain equality match
    # Simply define a hash for the table containing the symbolized field names to be handled
    #
    # Use a hash with :value to define a predefined matching clause:
    # :starts_with is the equivalent of "?%"
    # :contains is the equivalent of "%?%"
    # :is  and :is_not are the equivalent of "?"
    # :do_nothing forces this attribute to be skipped
    #
    # Subsequent symbols in the array can be used to modify the string
    # :strip_spaces removes all spaces from the string
    # :upcase makes the whole string uppercase
    #
    # The :condition can be specified to state the actual query condition
    # :starts with and :contains both default to "field_name LIKE ?"
    # :is_not default to "field_name <> ?"
    #
    # note that ? characters will be replaced by the field search value
    #
    # Optionally add a value (symbol or array of symbols or string specifying full join clause) for :joins
    # to specify specific tables to add to the inner join list
    AltConditions = {
      player_infos: {
        first_name: { value: :starts_with },
        middle_name: { value: :starts_with },
        nick_name: { value: :starts_with },
        notes: { value: :contains },
        younger_than: { value: :years,
                        condition: 'player_infos.birth_date is not null  AND ((current_date - interval ? )) < player_infos.birth_date' },
        older_than: { value: :years,
                      condition: 'player_infos.birth_date is not null  AND ((current_date - interval ?)) > player_infos.birth_date' }
      },
      pro_infos: {
        first_name: { value: :starts_with },
        middle_name: { value: :starts_with },
        nick_name: { value: :starts_with },
        less_than_career_years: { value: :is,
                                  condition: 'pro_infos.start_year is not null AND pro_infos.end_year IS NOT NULL  AND (pro_infos.end_year - pro_infos.start_year) < ?' },
        more_than_career_years: { value: :is,
                                  condition: 'pro_infos.start_year is not null AND pro_infos.end_year IS NOT NULL  AND (pro_infos.end_year - pro_infos.start_year) > ?' }
      },
      addresses: {
        street: { value: :starts_with },
        zip: { value: :starts_with }
      },
      player_contacts: {
        data: { value: %i[starts_with strip_non_alpha_numeric],
                condition: "regexp_replace(player_contacts.data, '\\W+', '', 'g') LIKE ?" }
      },
      not_trackers: {
        protocol_event_id: { value: :is,
                             condition: 'NOT EXISTS (select NULL from trackers t_inner where t_inner.protocol_event_id EQUALS_OR_IS_NULL AND t_inner.sub_process_id = :not_trackers_sub_process_id  AND t_inner.master_id = masters.id)', joins: NotTrackerJoin },
        sub_process_id: { value: :is, condition: 'TRUE', joins: NotTrackerJoin }
      },
      not_tracker_histories: {
        protocol_event_id: { value: :is,
                             condition: 'NOT EXISTS (select NULL from tracker_history th_inner where th_inner.protocol_event_id EQUALS_OR_IS_NULL AND th_inner.sub_process_id = :not_tracker_histories_sub_process_id AND th_inner.master_id = masters.id)', joins: NotTrackerHistoryJoin },
        sub_process_id: { value: :is, condition: 'TRUE', joins: NotTrackerHistoryJoin }
      },
      general_infos: {
        first_name: { value: :starts_with,
                      condition: '(player_infos.first_name LIKE ? OR pro_infos.first_name LIKE ? OR player_infos.nick_name LIKE ? OR pro_infos.nick_name LIKE ?)', joins: SimplePlayerJoin },
        last_name: { value: :is, condition: '(player_infos.last_name = ? OR pro_infos.last_name = ?)',
                     joins: SimplePlayerJoin },
        birth_date: { value: :is, condition: '(player_infos.birth_date = ? OR pro_infos.birth_date = ?)',
                      joins: SimplePlayerJoin },
        death_date: { value: :is, condition: '(player_infos.death_date = ? OR pro_infos.death_date = ?)',
                      joins: SimplePlayerJoin },
        start_year: { value: :is, condition: '(player_infos.start_year = ? OR pro_infos.start_year = ?)',
                      joins: SimplePlayerJoin },
        end_year: { value: :is, condition: '(player_infos.end_year = ? OR pro_infos.end_year = ?)',
                    joins: SimplePlayerJoin },
        college: { value: :is, condition: '(player_infos.college = ? OR pro_infos.college = ?)',
                   joins: SimplePlayerJoin },
        contact_data: { value: %i[starts_with strip_non_alpha_numeric],
                        condition: "regexp_replace(player_contacts.data, '\\W+', '', 'g') LIKE ?", joins: :player_contacts }
      }

    }.freeze

    # Don't automatically generate a join for specific AltConditions
    # This allows for a :joins definition in AltConditions to define a LEFT OUTER JOIN on the primary table, for example
    NoDefaultJoinFor = %i[general_infos not_trackers not_tracker_histories].freeze

    included do
    end

    class_methods do
      def init_nested_attribs
        # Nested attributes for advanced search form.
        # These items will be extended dynamically by the external_id models when they are initially configured
        accepts_nested_attributes_for(*Master::MasterNestedAttribs)
      end

      def set_associations_for_subject_searches
        # inverse_of required to ensure the current_user propagates between associated models correctly
        has_many :player_infos, -> { order(Master.subject_info_rank_order_clause) }, inverse_of: :master
        has_one :player_info, -> { order(Master.subject_info_rank_order_clause) }, inverse_of: :master
        has_many :pro_infos, inverse_of: :master
        has_many :player_contacts, -> { order(RankNotNullClause) }, inverse_of: :master
        has_many :addresses, -> { order(RankNotNullClause) }, inverse_of: :master

        # Associations to allow advanced searches for NOT
        has_many :not_tracker_histories, lambda {
                                           order(Master::TrackerHistoryEventOrderClause)
                                         }, class_name: 'TrackerHistory'
        has_many :not_trackers, -> { order(Master::TrackerEventOrderClause) }, class_name: 'Tracker'

        # This association is provided to allow 'simple' search on names in player_infos OR pro_infos
        has_many :general_infos, class_name: 'ProInfo'
      end

      def subject_info_rank_order_clause
        PlayerInfoRankOrderClause
      end

      # Build a Master search using the Master and nested attributes passed in
      # Any attributes that are nil will be rejected and will not appear in the query
      # Tables will only be joined if the nested attributes for the association have one or more
      # attributes that are not nil
      def search_on_params(params, conditions = {})
        joins = [] # list of joined tables
        wheres = {} # set of equality where clauses
        wheresalt = [nil, {}] # list of non-equality where clauses (such as LIKE)
        selects = ['masters.id', 'masters.rank as master_rank', 'masters.pro_info_id', 'masters.pro_id', 'masters.msid']

        params.each do |params_key, params_val|
          if params_val.is_a? Hash

            if params_val.first.first == '0'
              # Grab the first array item from the parameters if there is one to reset the context
              params_val = params_val.first.last
            end

            # Handle nested attributes
            # Get the key name for the table by removing the _attributes extension from the key

            if params_key.to_s.include? '_attributes'
              condition_key = params_key.to_s.gsub('_attributes', '').to_sym
              r = Master.reflect_on_association(condition_key)
              logger.debug "checking master association #{condition_key}"
              logger.debug "r: #{r}"
              logger.debug "condition_key: #{condition_key}"
              logger.debug "Reflection: #{r.klass.table_name}"
              logger.debug "Source Reflection: #{r.source_reflection.name && r.source_reflection.name}"
              condition_table = if r.klass # r.source_reflection #
                                  r.klass.table_name # r.source_reflection.name.to_s #
                                else
                                  r.plural_name.to_s
                                end
            else
              # Generate a pluralized table name for associations that are has_one
              condition_table = params_key.to_s.pluralize
            end

            # Keep only non-nil attributes for the primary wheres that don't have an alternative condition string

            basic_condition_attribs = params_val.select do |key1, v1|
              !v1.nil? && !alt_condition(condition_key, [key1, v1])
            end

            # Pull the attributes with an alternative condition string (note that this returns nil values too)
            # format: {condition: condition_clause, reference: {reference_name => value}, joins: joins_clauses}
            alt_condition_attribs = params_val.reject { |_, v1| v1.nil? }.map { |v2| alt_condition(condition_key, v2) }

            logger.debug "Param: #{params_key} has condition_table: #{condition_table}"
            logger.debug "basic_condition_attribs #{basic_condition_attribs} -- alt_condition_attribs #{alt_condition_attribs}"

            # If we have a set of attributes that is not empty
            # add the equality conditions to the list of wheres
            if !basic_condition_attribs.empty? || !alt_condition_attribs.empty?

              # When this is a basic condition
              unless basic_condition_attribs.empty?
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
              unless alt_condition_attribs.empty?
                logger.info "Merging alternative conditions FOR #{alt_condition_attribs}"
                # For each alternative condition attribute, check if it has a defined condition, then
                # generate alternative where clauses
                alt_condition_attribs.each do |alt_condition_attrib|
                  next unless alt_condition_attrib && alt_condition_attrib[:condition]

                  logger.info "Alt Condition: #{alt_condition_attrib[:condition]}"
                  wheresalt[0] = "#{wheresalt[0]}#{wheresalt[0] ? ' AND ' : ''}#{alt_condition_attrib[:condition]}"
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
                    logger.info 'Not Adding alt joins'
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
        return nil if wheres.empty? && !wheresalt.first

        logger.debug "joins: #{joins}"
        logger.debug "Standard wheres: #{wheres}"
        logger.debug "Alt wheres: #{wheresalt}"
        res = Master.select(selects).joins(joins).where(wheres).distinct
        res = res.where(wheresalt.first, wheresalt.last) if wheresalt.first

        res.default_sort
      end

      def alt_condition(table_name, condition)
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

        return {} if cond_op == :do_nothing || cond_op == :is_not_null && (cval.blank? || cval == '(null)')

        cond_op = [cond_op] unless cond_op.is_a? Array

        refname = "#{table_name}_#{ckey}"

        alt = if altdef[:condition]
                altdef[:condition]
              elsif cond_op.include?(:starts_with) || cond_op.include?(:contains)
                "#{table_name}.#{ckey} LIKE ?"
              elsif cond_op.include?(:is_not)
                "#{table_name}.#{ckey} <> ?"
              else
                "#{table_name}.#{ckey} = ?"
              end

        if altdef[:value].is_a? Array
          altdef[:value].each do |d|
            if d == :strip_spaces
              cval = cval.gsub(' ', '')
            elsif d == :strip_non_alpha_numeric
              cval = cval.gsub(/\W+/, '')
            elsif d == :upcase
              cval = cval.upcase
            end
          end
        end

        cval = nil if cval == '(null)'

        eoin = if cval.nil?
                 'IS NULL'
               else
                 '= ?'
               end
        alt = alt.gsub('EQUALS_OR_IS_NULL', eoin)

        alt = alt.gsub('?', ":#{refname}")

        cvaltotal = "#{cval}%" if cond_op.include? :starts_with
        cvaltotal = "%#{cval}%" if cond_op.include? :contains
        cvaltotal = cval if cond_op.include? :is
        cvaltotal = "#{cval} years" if cond_op.include? :years
        cvaltotal = cval.to_s if cond_op.include? :is_not

        joins = altdef[:joins]

        { condition: alt, reference: { refname.to_sym => cvaltotal }, joins: joins }
      end

      #
      # Provide a default ordered scope, potentially limited by the results_limit attribute
      # Note that this sorts first, based on the Master rank, which is calculated through a trigger from player info accuracy
      # @param [ActiveRecord::Model || ActiveRecord::Relation] res previous set of results to build on, or a base class
      # @return [ActiveRecord::Relation] <description>
      def default_sort
        if results_limit
          order(MasterRank).limit(results_limit)
        else
          order(MasterRank).all
        end
      end
    end
  end
end
