# frozen_string_literal: true

# Handle the evaluation of general calc_action_if methods for:
#   conditions (such as creatable_if)
#   validations (to ensure data is valid)
#   return of values, lists and instances matching the conditions
#
# Conditions may be deeply nested to handle the equivalent of OR(AND, NOT(OR),...)
# Each level is calculated through two distinct mechanisms: query conditions and non-query conditions
#
# Query conditions are directly fulfilled by generating a query scope. For conditions where all should match
# then a single query result provides the result. For conditions where any should match, the basic scope is used
# to run each condition in turn.
#
# Non-query conditions are those that reference the current instance or user in some way and are therefore
# not a table that can be joined in a query. They are evaluated through specific logic, and this can be extended to
# provide new forms of evaluation.
#
# Nested conditions may occur within either form of condition, and are handled by just recursively instantiating
# the outer class, ConditionalActions.
#
# In addition to the evaluation of basic conditions against plain values, comparison values may be pulled from
# referencing other tables and non-query conditions.

module CalcActions
  module Calculate
    extend ActiveSupport::Concern

    include FieldDefaults
    include Common

    # We won't use a query join when referring to tables based on these keys
    NonJoinTableNames = %i[this parent embedded_item referring_record top_referring_record this_references parent_references
                           parent_or_this_references user master condition value hide_error invalid_error_message
                           role_name reference ids_referencing and_latest_matches].freeze

    ReturnTypes = %w[return_value return_value_list return_result return_all_results].freeze

    included do
      attr_accessor :condition_scope
    end

    private

    # Primary method to calculate conditions
    def do_calc_action_if
      return @early_return if early_return?

      # Final result for all selections
      final_res = true

      # calculate that all the following sets of conditions are true:
      # (:all conditions) AND (:not_all conditions) AND (:any conditions) AND (:not_any conditions)
      #
      # selection_type=all|any|not_all|not_any:
      #   table_name:
      #     condition: string|reference_condition
      #   selection_type:
      #     table_name: ...

      action_conf.each do |condition_type, condition_config_array|
        # If the condition definition is not an array, make it one
        condition_config_array = [condition_config_array] unless condition_config_array.is_a? Array

        # Save the original key, representing the condition type, such as :not_all_fields_must_match
        @orig_cond_type = @condition_type = condition_type

        # If the @condition_type key is not a selection type, use the original @condition_type
        # value since it represents a table name or other reference item
        @condition_type = selection_type?(@condition_type) || @condition_type

        # Initialize the loop result, as true for all, not_any, since they AND results,
        # not_all and any OR results, so must be initialized to false
        @loop_res = @condition_type.in?(%i[all not_any])
        @orig_loop_res = @loop_res

        # For each condition config definition, run the main tests
        condition_config_array.each do |condition_config|
          setup_condition_config(condition_config)
          calc_base_query

          #### :all ####
          case @condition_type
          when :all
            condition_type_all
          #### :not_all ####
          when :not_all
            condition_type_not_all
          #### :any ####
          when :any
            condition_type_any
          #### :not_any ####
          when :not_any
            condition_type_not_any
          else
            raise FphsException, "Incorrect condition type specified when calculating action if: #{@condition_type}"
          end

          log_results

          # We can end the loop, unless the last result was a success
          break unless @loop_res
        end

        final_res &&= @loop_res
        break unless final_res
      end

      # Return the final result
      !!final_res
    end

    # Generate the query for the @condition_scope.
    # This basically generates the query that will be used to handle queries against tables, and
    # acts as the scope around individual non query conditions
    # @param conditions [Hash] conditions as a standard ActiveQuery hash {table: {field: value}, ...}
    # @param extra_conditions [Array]
    # @param bool [String] value 'AND' or 'OR' used to replace the BoolTypeString placeholder
    # @return [ActiveQuery::Relation] the final @condition_scope
    def gen_condition_scope(conditions, extra_conditions = [], bool = 'AND')
      @condition_scope = if conditions.first && conditions.first.last&.length == 0
                           # If no conditions are specified for this table, don't apply it as a where clause
                           # since it always invalidates the query
                           # This typically happens as a result of extra_conditions being
                           # applied to non query conditions,
                           # (references such as this, this_references etc being the key name, rather than a table)
                           @base_query
                         else
                           # Conditions are available - apply them as a where clause on top of the base query
                           @base_query.where(conditions)
                         end

      # For extra_conditions related to non query conditions, apply them directly
      if extra_conditions.present? && extra_conditions[0]&.strip&.present?
        # Handle replacement of AND or OR into the generated query conditions SQL
        extra_conditions[0].gsub!(BoolTypeString, bool)
        @condition_scope = @condition_scope.where(extra_conditions)
      end

      if @and_latest_matches
        tname = @and_latest_matches.first.first
        latest_id = @condition_scope.select("#{tname}.id and_match_res_id").order(and_match_res_id: :desc).first&.and_match_res_id
        @and_latest_matches[tname][:id] = latest_id
        @condition_scope = @base_query.where(@and_latest_matches)
      else
        @condition_scope = @condition_scope.order(id: :desc).limit(1) unless @this_val_where
      end

      # Return the usable @condition_scope
      @condition_scope
    end

    # Get any requested return_value, return_value_list, return_result or return_all_results
    # The results are set in the instance attribute #this_val
    # The instance variable @this_val_where defines the return requirements, or may be
    # nil if there is no requirement to return anything
    def calc_return_types
      # Handle the return of requested values, lists or results (instances) if the definition
      # requested this
      return unless @this_val_where

      # The condition scope must be ordered in reverse, as always, and if we
      # only are requesting a single result then limit 1, otherwise get all results for the list
      cs = @condition_scope.order(id: :desc)
      if return_value_from_query? || return_result_from_query?
        cs = cs.limit(1)
        # Clean up the current value to avoid issues
        self.this_val = nil
      end
      first_cond_res = cs.first

      # If a result was found process the returns, otherwise continue
      return unless first_cond_res

      # The instance @condition_scope can reflect the successful query scope
      @condition_scope = cs

      # The result instance now gets the defined association
      # TODO: check this against a list of valid associations
      all_res = self.this_val = if first_cond_res.respond_to?(@this_val_where[:assoc])
                                  first_cond_res.send(@this_val_where[:assoc])
                                else
                                  [first_cond_res]
                                end
      first_res = all_res.first

      # If we got a result from the asssociation process it, otherwise continue
      return unless first_res

      # The table name for the result we need
      tn = first_res.class.table_name
      # The field to return, checked by matching the defined field name against the attributes of the class
      fn = first_res.class.attribute_names.select { |s| s == @this_val_where[:field_name].to_s }.first
      # For a return_result (instance), the table name of the item to return was specified
      tv_tn = UserBase.clean_table_name(ModelReference.record_type_to_table_name(@this_val_where[:table_name]))

      # If we have a table name from the query result use it, otherwise use the return_result table name
      if tn
        rquery = @condition_scope.reorder("#{tn}.id desc")
      elsif tv_tn.present?
        rquery = @condition_scope.reorder("#{tv_tn}.id desc")
      end

      if return_result_from_query?
        raise "return_result clean table name is blank for (#{@this_val_where[:table_name]})" if tv_tn.blank?

        # Get the return_result instance by getting the first result from the query, then finding the instance
        # by id to get a clean result
        rquery = rquery.select("#{tv_tn}.*")
        self.this_val = first_res.class.find(rquery.first.id)
      elsif return_all_results_from_query?
        raise "return_result clean table name is blank for (#{@this_val_where[:table_name]})" if tv_tn.blank?

        # Get the return_result instance by getting the first result from the query, then finding the instance
        # by id to get a clean result
        rquery = rquery.select("#{tv_tn}.*").reload
        self.this_val = first_res.class.where(id: rquery.pluck(:id)).reload
      else
        # Run the results query and get either a single result or a list
        rvals = rquery.pluck("#{tn}.#{fn}")
        self.this_val = rvals.first if return_value_from_query?
        self.this_val = rvals if return_value_list_from_query?
      end
    end

    # Generate the query conditions to allow
    # values to be matched from another referenced record (or this)
    # Each type of reference is related to the current instance and pulls
    # one or more results to be used directly in a query condition
    #
    # These are defined something like:
    #   activity_log__player_contact_phone:
    #     extra_log_type: 'do_something'
    #     field_to_compare:
    #       <type_of_reference>: attribute or hash

    # @param val [Hash] the definition of the matching requirements
    # @param ref_table_name [String | Symbol] the table name to reference in
    #                                         this_references / parent_references conditions
    # @return [String | Number | Array] return val to be matched
    def generate_match_query_condition(val, ref_table_name)
      val_item_key = val.first.first
      val_item_value = val.first.last

      # If a specific table was not set (we have a select type such as all, any)
      # then we can assume that we are referring to 'this' current record
      if selection_type?(val_item_key)
        val_item_key = :this
        val = { this: val }
      end

      if val_item_key == :this && !val_item_value.is_a?(Hash)
        # Get a literal value from 'this' to be compared
        val = attribute_from_instance(@current_instance, val_item_value)

      elsif val_item_key == :parent && !val_item_value.is_a?(Hash)
        # Get a literal value from the current instance's parent to be compared
        # Note: parent_item is only available on NfsStore::Container
        from_instance = @current_instance.parent_item
        raise FphsException, 'No parent record found for condition' unless from_instance

        val = attribute_from_instance(from_instance, val_item_value)

      elsif val_item_key == :embedded_item
        from_instance = @current_instance.embedded_item
        val = from_instance && attribute_from_instance(from_instance, val_item_value)
      elsif val_item_key == :referring_record && !val_item_value.is_a?(Hash)
        # Get a literal value from the current instance's referring_record.
        # This is a record referring to the current instance.
        # A referring record is either based on the context of the current request (from a controller)
        # or if there is only a single model reference referring to the current instance,
        # that is used instead
        # This is often an activity_log record referring to the current activity_log
        # If no referring record exists, the result is nil
        from_instance = @current_instance.referring_record
        val = from_instance && attribute_from_instance(from_instance, val_item_value)

      elsif val_item_key == :top_referring_record && !val_item_value.is_a?(Hash)
        # Get a literal value from the current instance's top_referring_record.
        # This is the top record in the hierarchy referring to the current instance.
        # A referring record is either based on the context of the current request (from a controller)
        # or if there is only a single model reference referring to the current instance,
        # that is used instead
        # This is often an activity_log record referring to the current activity_log
        # If no referring record exists, the result is nil
        from_instance = @current_instance.top_referring_record
        val = from_instance && attribute_from_instance(from_instance, val_item_value)

      elsif val_item_key == :reference && !val_item_value.is_a?(Hash)
        # Get a literal value from the current instance's reference,
        # the current to_record in a model reference iteration.
        # If no reference exists, the result is nil
        from_instance = @current_instance.reference
        val = from_instance && attribute_from_instance(from_instance, val_item_value)

      elsif val_item_key == :ids_referencing
        # Get an array of ids for a specified set of "from" items
        # where the items reference a "target" item, based on a filter
        # This is different from `this_references` since "from" is unrelated
        # to the current instance
        # id:
        #   ids_referencing:
        #     target:
        #       external_items:
        #         rec_type: val
        #     from:
        #       activity_log_items:
        #         extra_log_type: act1
        #         return: return_all_results
        to_record_type = val_item_value[:target].first.first.to_s.singularize
        filter_by = val_item_value[:target].first.last
        from_item_def = val_item_value[:from]

        ca = ConditionalActions.new from_item_def, @current_instance
        from_items = ca.get_this_val
        unless from_items.present?
          raise FphsException,
                'ids_referencing from items was not found - '\
                'ensure return: return_all_results is specified and at least one result is returned'
        end

        refs = from_items.map do |item|
          item.save_trigger_results = current_instance.save_trigger_results
          item.current_user = current_instance.current_user
          ModelReference.find_references(item, to_record_type:, filter_by:, active: true).pluck(:from_record_id)
        end
        val = refs.flatten.compact
      elsif val_item_key.in? %i[this_references parent_references parent_or_this_references]
        val = references_values(val_item_key, val_item_value, ref_table_name)
      elsif val_item_key == :user
        # Get an attribute or role names for the current user (as set on the current instance master)
        #
        # In the simplest form, we can match the current instance user_id (creator or latest updater)
        # against the current user, using a definition like this:
        #   all_creator:
        #     this:
        #       user_id:
        #         user: id
        #
        # Also, consider checking if an instance has an attribute that matches one of the current
        # user's roles:
        #       all:
        #         this:
        #           select_who:
        #             user: role_name

        att = val_item_value
        user = @current_instance.current_user
        raise FphsException, "No user found for condition in #{@current_instance}" unless user

        val = if att.is_a?(Hash)
                val
              elsif att == 'role_name'
                # The value to match against is an array of the user's role names
                user.role_names
              else
                # The value to match against is the value of the specified attribute
                user.attributes[att]
              end

      end

      val
    end

    #
    # Get possible values from records referenced by this instance, or this instance's referring record (parent)
    # @return [true | Array] - returns true (for :exists tag) or array of values corresponding to the required reference
    def references_values(val_item_key, val_item_value, ref_table_name)
      case val_item_key
      when :this_references
        # Identify all records this instance references
        from_instance = @current_instance
      when :parent_references
        # Identify all records this instance's referring record (parent) references
        from_instance = @current_instance.referring_record
      when :parent_or_this_references
        # Identify all records this instance's referring record (parent) references,
        # or if there is no parent, this record references
        from_instance = @current_instance.referring_record || @current_instance
      end

      if val_item_value.is_a?(Hash)
        # If the expected value is a hash, this indicates that a specific type of referenced record is required,
        # and a field is to be returned from any matching records of this type
        # For example, the following definition will match addresses where
        # city and zip match
        # and the current instance (an activity log) references a activity_log__player_contact_phone record where the
        # set_related_player_contact_rank field of the referenced record equals the rank of the address
        #
        #  addresses:
        #    city: 'portland'
        #    zip: '12345'
        #    rank:
        #      this_references:
        #        activity_log__player_contact_phone: set_related_player_contact_rank

        att = val_item_value.first.last
        to_table_name = val_item_value.first.first

      else
        # If the expected value is not a hash, we are probably performing a simple match to find a
        # record of a specific type referenced by the instance, rather than any record of that type
        # that is associated with the master.
        # For example, to just find addresses referenced by an activity log (rather than all of them the master has),
        # the definition looks like:
        #  addresses:
        #    city: 'portland'
        #    zip: '12345'
        #    id:
        #      this_references: id
        #
        # In this case we will be matching addresses where
        # city and zip match
        # and the instance (an activity log) references an address record where the
        # the address id is one of those referenced.
        # In other words, it will only pick an address that is referenced by this activity_log,
        # not other addresses that belong to this master.

        att = val_item_value
        # We will filter on the main table name if it is actually a table, not something like 'parent_references'
        to_table_name = nil if non_join_table_name?(ref_table_name)

      end

      if val_item_key == :exists
        # Simply get a true result if instance found and {exists: true} or
        # instance not found and {exists: false}
        val = (!!expected_val == !!from_instance)
      elsif !from_instance
        raise FphsException, "No referring record specified when using #{val_item_key} in " \
                             "#{@current_instance.class.name} #{@current_instance.id}"
      else
        # Now go ahead and get the possible values to use in the condition
        val = []
        # Ensure we only get results from an active (not disabled) model reference, and don't recalculate
        # showable filter since this might recurse infinitely
        model_refs = from_instance.model_references(active_only: true, showable_only: false)
        Rails.logger.info '*** No model_refs found' if model_refs.empty?
        # filter it to return only those matching the required to_record_type (if necessary)
        if to_table_name
          model_refs = model_refs.select { |r| r.to_record_type == to_table_name.to_s.singularize.ns_camelize }
          Rails.logger.info "*** No model_refs found for table name: #{to_table_name}" if model_refs.empty?
        end

        # Get the specified attribute's value from each of the model references
        # Generate an array, allowing the conditions to be IN any of these
        val = model_refs.map { |mr| mr.to_record.attributes[att] }
      end
      val
    end

    #
    # Based on match query conditions being generated, now setup the value comparisons.
    # This may produce extra conditions to be pushed into the query at runtime, or
    # basic joined conditions.
    def generate_query_condition_values(val, table_name, field_name)
      return if val.in?(ReturnTypes)
      return if handle_condition_tag(val, table_name, field_name)
      return if handle_and_matches(val, table_name, field_name)

      @condition_values[table_name] ||= {}
      val = val.reject { |r| r.in?(ReturnTypes) } if val.is_a?(Array)
      @condition_values[table_name][field_name] = dynamic_value(val)
    end

    def handle_and_matches(val, table_name, field_name)
      return unless field_name == :and_latest_matches

      table_name = table_name.id_underscore

      vals = val.transform_values { |v| dynamic_value(v) }
      @and_latest_matches = { table_name => vals }
    end

    #
    # When a condition: {} is specified, handle and return it. If not specified, return nil
    def handle_condition_tag(val, table_name, field_name)
      return unless val.is_a?(Hash)

      condition = val[:condition]
      return unless condition

      # Special cases
      condition = '= ANY' if condition == 'in?'
      condition = '= ANY REV' if condition == 'include?'

      # If we have a non-equals condition specified, generate the extra conditions
      if condition.in?(ValidExtraConditions)
        # A simple unary or binary condition

        # Setup the query conditions array ["sql", cond1, cond2, ...]
        if @extra_conditions[0].blank?
          @extra_conditions[0] = ''
        else
          @extra_conditions[0] += " #{BoolTypeString} "
        end

        if condition.in? UnaryConditions
          # It is a unary condition, extend the SQL
          @extra_conditions[0] += "#{table_name}.#{field_name} #{condition}"
        else
          # It is a binary condition, extend the SQL and conditions
          vc = ValidExtraConditions.find { |c| c == condition }
          vv = dynamic_value(val[:value])
          # Allow simplified "<>" not equals check. Return true if value is NULL.
          added_check = "#{table_name}.#{field_name} IS NULL or" if vc == '<>'
          @extra_conditions[0] += "(#{added_check} #{table_name}.#{field_name} #{vc} (?))"
          @extra_conditions << vv
        end

      elsif condition.in?(ValidExtraConditionsArrays)
        # It is an array condition

        veca_extra_args = ''

        # Setup the query conditions array ["sql", cond1, cond2, ...]
        if @extra_conditions[0].blank?
          @extra_conditions[0] = ''
        else
          @extra_conditions[0] += " #{BoolTypeString} "
        end

        # Extend the SQL and conditions
        vc = ValidExtraConditionsArrays.find { |c| c == condition }

        raise FphsException, 'Use a value: key with a condition:' unless val.key?(:value)

        vv = dynamic_value(val[:value])

        negate = (val[:not] ? 'NOT' : '')

        leftop = '?'

        if vc == '&&' || vc.end_with?(' REV') || vv.is_a?(Array)
          leftop = 'ARRAY[?]'
          leftop += '::varchar[]' if vv.first.is_a? String
        end

        veca_extra_args = ', 1' if vc.include?('ARRAY_LENGTH')

        rightop = "#{table_name}.#{field_name}#{veca_extra_args}"
        if vc.end_with?(' REV')
          ro = rightop
          rightop = leftop
          leftop = ro
          vc = vc.sub(' REV', '')
        end

        @extra_conditions[0] += "#{negate} (#{leftop} #{vc} (#{rightop}))"
        @extra_conditions << vv
      elsif condition
        raise FphsException,
              "calc_action condition '#{condition}' for #{table_name} and #{field_name} is not recognized"
      end

      condition
    end

    # If we are expecting values or results to be returned, handle the setup for this here
    # @param val [String | Array] a string or array that may contain a required return definition
    # @return [nil | Hash] defining the return definition
    def generate_returns_config(val, join_table_name, field_name)
      # Check if the definition expects a return value, list or result
      mode = nil
      if expected_value_requests_return? :value, val
        mode = 'return_value'
      elsif expected_value_requests_return? :result, val
        mode = 'return_result'
      elsif expected_value_requests_return? :value_list, val
        mode = 'return_value_list'
      elsif expected_value_requests_return? :all_results, val
        mode = 'return_all_results'
      end

      # If a return mode was specified, set this up to be used in the query
      return unless mode

      @this_val_where = {
        assoc: join_table_name,
        field_name:,
        table_name: ModelReference.record_type_to_ns_table_name(join_table_name).to_sym,
        mode:
      }
    end

    #
    # Decide if an early return is needed:
    # - action_conf is not a hash or it is empty (conditional result = true)
    # - simple conditions to always return
    #     never: true (conditional result = false)
    #     always: true (conditional result = true)
    # Sets the instance attribute @early_return with the value to actually
    # return if an early return is needed
    # @return [true|false] - returns true if an early return is required
    def early_return?
      @early_return = nil
      return @early_return = true unless action_conf.is_a?(Hash) && action_conf.first
      return @early_return = true if action_conf[:always]

      @early_return = false if action_conf[:never]
      # An early return is needed if the value is not nil from matching one of the conditions above
      !@early_return.nil?
    end

    #
    # Setup the condition config for this loop's condition
    # @param [Hash] condition_config
    def setup_condition_config(condition_config)
      @condition_config = condition_config.dup

      iem = @condition_config.delete(:invalid_error_message)
      # Check if the first key is a selection type. If it is, wrap it in a
      # {this: original hash} to make it easier to process consistently
      this_condition_config = if selection_type?(@condition_config.first.first)
                                self.top_level_error_above = top_level_error
                                add_this = true
                                { this: @condition_config }
                              else
                                @condition_config
                              end
      self.top_level_error = iem || top_level_error

      @non_query_conditions = NonQueryCondition.new(current_instance:,
                                                    condition_config: this_condition_config,
                                                    return_failures:,
                                                    return_this:,
                                                    top_level_error:,
                                                    top_level_error_above:)

      @condition_config[:invalid_error_message] = iem if iem
      @condition_config = this_condition_config if add_this
      @condition_config
    end

    # Generate query conditions to support the conditional configuration.
    # Each condition definition decides if it is a query or non-query condition and
    # sets up conditions to support this.
    # Query conditions may incorporate joined tables (inner and left joins) into the query
    # as well as formulating the ActiveRecord queries to support this.
    # Non-query conditions build on the base query when evaluated, and this method just
    # sets up some structures to support this.
    def calc_base_query
      @join_tables = []
      @condition_values = {}
      @extra_conditions = []
      @sub_conditions = {}

      @condition_config.each do |c_table, t_conds|
        c_table = @current_instance.class.definition.resource_name if c_table == :definition_resources
        join_table_name = c_table.to_sym
        table_name = ModelReference.record_type_to_table_name(c_table).to_sym

        if selection_type?(table_name)
          # Nested conditions are ignored, since they are
          # handled directly in the condition processing logic
        elsif c_table == :invalid_error_message
          self.top_level_error_above ||= top_level_error
          self.top_level_error ||= t_conds
          @non_query_conditions.top_level_error = top_level_error
          @non_query_conditions.top_level_error_above = top_level_error_above
        else
          @non_query_conditions.table = table_name
          t_conds.each do |field_name, val|
            if field_name == :invalid_error_message
              # self.top_level_error_above = top_level_error
              # self.top_level_error = val
              # @non_query_conditions.top_level_error = top_level_error
              # @non_query_conditions.top_level_error_above = top_level_error_above
              next
            end

            if val.is_a?(Hash) && !val.key?(:element) && !val.key?(:calculate)
              # Since the conditional value is actually a hash, we need to
              # get the value to be matched from another referenced record (or this)
              # Generate the query condition to do this
              val = generate_match_query_condition(val, join_table_name)
            end

            # non query conditions are those aren't formulated with a series of
            # inner joins on the master. They are handled as individual queries.
            next if @non_query_conditions.add(table_name, field_name, val)

            # We have finally decided that this is a regular query condition
            # Handle setting up the condition values
            generate_query_condition_values(val, table_name, field_name)

            # And handle any returns value / results config
            generate_returns_config(val, join_table_name, field_name)

            # We can add this table to the joins
            @join_tables << join_table_name
          end
        end
      end

      # Make the list of tables to be joined valid (in case anything slipped through) and unique
      @join_tables = (@join_tables - NonJoinTableNames).uniq

      return if setup_no_masters

      limit_to_masters
      setup_base_query
    end

    def setup_no_masters
      # Specify `no_masters: {}` at the top level to directly query the record, rather than doing
      # an inner join on the masters table
      return unless @condition_config.respond_to?(:key?) &&
                    @condition_config.key?(:no_masters) ||
                    @condition_config.map(&:first).include?(:no_masters)

      # Use the first specified table as the base, not joining on masters table
      @join_tables.delete_if { |a| a == :no_masters }
      rn = @join_tables.first
      r = Resources::Models.find_by(resource_name: rn)
      raise FphsException, "No resource found for #{rn} with no_masters specified in calc_actions" unless r

      c = r.class_name.constantize
      @base_query = c.all
      @current_scope = c.all
      true
    end

    #
    # Specify `masters: {...}` to not tie the action to the item's current master, but instead use the
    # set of masters specified. `{}` indicates any master, or use standard conditions to specify a list of ids,
    # such as { id: [1,2,3] }
    def limit_to_masters
      if @condition_config.respond_to?(:key?) && @condition_config.key?(:masters) ||
         @condition_config.map(&:first).include?(:masters)
        # Use the full masters table as the base, allowing the configuration to limit the masters records if needed
        @base_query = Master.all
        @current_scope = Master.all
        @join_tables.delete_if { |a| a == :masters }
      end
    end

    def setup_base_query
      @base_query = if @join_tables.first == :users
                      # Get the users records without a join to the masters table, which makes no sense
                      @current_scope = User.all
                      User.all
                    elsif %i[all not_all].include? @condition_type
                      # Inner join, since our conditions require the existence of records in the joined tables
                      @current_scope.joins(@join_tables)
                    else
                      # Left join, since our conditions do not absolutely require the existence of
                      # records in the joined tables
                      @current_scope.includes(@join_tables)
                    end
    end

    def condition_type_all
      @cond_res = true
      @res_q = true
      # equivalent of (cond1 AND cond2 AND cond3 ...)
      # These conditions are easy to handle as a standard query
      # @this_val_where check allows a return_value definition to be used alone without other conditions
      unless @condition_values.empty? && @extra_conditions.empty? && !@this_val_where
        gen_condition_scope @condition_values, @extra_conditions
        calc_return_types
        @res_q = calc_nested_query_conditions
        merge_failures(@condition_type => @condition_config) unless @res_q
      end

      @res_q &&= @non_query_conditions.condition_type_all

      @cond_res &&= !!@res_q
      @loop_res &&= @cond_res
    end

    def condition_type_not_all
      @cond_res = true
      @res_q = true
      # equivalent of NOT(cond1 AND cond2 AND cond3 ...)
      unless @condition_values.empty? && @extra_conditions.empty?
        gen_condition_scope @condition_values, @extra_conditions
        calc_return_types
        @res_q = calc_nested_query_conditions
      end

      @res_q &&= @non_query_conditions.condition_type_not_all
      @cond_res &&= !@res_q

      # Not all matches - return all possible items that failed
      merge_failures(@condition_type => @condition_values) unless @cond_res
      merge_failures(@condition_type => @non_query_conditions.conditions) unless @cond_res

      @loop_res ||= @cond_res
      @loop_res
    end

    def condition_type_any
      unless @extra_conditions.empty?
        raise FphsException,
              '@extra_conditions not supported with any / not_any conditions'
      end

      @cond_res = false
      @res_q = false
      # equivalent of (cond1 OR cond2 OR cond3 ...)

      if @condition_values.empty?
        # Reset the previous condition_scope, since it could be carrying unwanted joins from an all, not_any condition
        @condition_scope = nil
        reset_scope = nil
      else

        @condition_values.each do |table, fields|
          fields.each do |field_name, expected_val|
            gen_condition_scope({ table => { field_name => expected_val } }, @extra_conditions, 'OR')
            calc_return_types
            @res_q = !@condition_scope.empty?

            break if @res_q
          end
          break if @res_q
        end

        reset_scope = @base_query.order(id: :desc).limit(1)
      end

      # Reset the condition scope, since gen_condition_scope will have messed with it
      @condition_scope = reset_scope
      @res_q ||= calc_nested_query_conditions return_first_false: false unless @res_q || @condition_scope.nil?
      merge_failures(@condition_type => @condition_values) unless @res_q

      @res_q ||= @non_query_conditions.condition_type_any
      @skip_merge ||= @non_query_conditions.skip_merge
      merge_failures(@condition_type => @non_query_conditions.conditions) unless @res_q

      @cond_res = @res_q
      @loop_res ||= @cond_res
      @loop_res
    end

    def condition_type_not_any
      unless @extra_conditions.empty?
        raise FphsException,
              '@extra_conditions not supported with any / not_any conditions'
      end

      @cond_res = true
      # equivalent of NOT(cond1 OR cond2 OR cond3 ...)
      # also equivalent to  (NOT(cond1) AND NOT(cond2) AND NOT(cond3))

      if @condition_values.empty?
        # Reset the previous condition_scope, since it could be carrying unwanted joins from an all, not_any condition
        @condition_scope = nil
        reset_scope = nil
      else

        @condition_values.each do |table, fields|
          fields.each do |field_name, expected_val|
            gen_condition_scope({ table => { field_name => expected_val } }, @extra_conditions, 'OR')
            calc_return_types
            @res_q = !@condition_scope.empty?
            merge_failures(@condition_type => { table => { field_name => expected_val } }) if @res_q
            @cond_res &&= !@res_q
            break unless @cond_res && !return_failures
          end
          break unless @cond_res && !return_failures
        end

        reset_scope = @base_query.order(id: :desc).limit(1)
      end

      # Reset the condition scope, since gen_condition_scope will have messed with it
      @condition_scope = reset_scope
      if @cond_res && !@condition_scope.nil?
        @res_q = calc_nested_query_conditions return_first_false: false
        @cond_res &&= !@res_q
      end

      @cond_res &&= @res_q = @non_query_conditions.condition_type_not_any
      @loop_res &&= @cond_res
    end

    def calc_non_query_condition(table, field_name, expected_val)
      @non_query_conditions.current_instance = current_instance
      @non_query_conditions.table = table
      @non_query_conditions.field_name = field_name
      @non_query_conditions.condition_def = expected_val
      @non_query_conditions.return_failures = return_failures
      @non_query_conditions.calc_result
    end

    # Calculate the sub conditions for this level if it contains any of the selection types
    # @param return_first_false [true | false] return immediately on the first condition that fails
    #   to match. This also controls whether results are combined through AND or OR
    # @return [true | false] return the result of the evaluated conditions
    def calc_nested_query_conditions(return_first_false: true)
      res = return_first_false
      begin
        # The query didn't return a result - therefore the condition evaluates to false
        # We rescue it here, since this is a common point for a poor SQL definition to fail
        return false if @condition_scope.empty?
      rescue StandardError => e
        Rails.logger.error "#{e}\n#{@condition_scope.to_sql}"
        raise e
      end

      # Combine sub condition results if they are specified
      # This sends the current @condition_scope as the basis for evaluation.
      @condition_config.each do |c_type, t_conds|
        # If this is a sub condition (the key is one of :all, :any, :not_any, :not_all)
        # go ahead and calculate the sub conditions results by instantiating a ConditionalActions class
        # with the scope as the current condition scope from the query
        st = selection_type? c_type
        next unless st

        ca = ConditionalActions.new({ c_type => t_conds }, current_instance, current_scope: @condition_scope,
                                                                             return_failures:,
                                                                             return_this:,
                                                                             top_level_error:,
                                                                             top_level_error_above:)
        res_a = ca.calc_action_if

        if return_first_false
          res &&= res_a
          return nil unless res
        else
          res ||= res_a
        end

        # @this_val ||= ca.this_val
      end

      res
    end

    # Check if this is a key we won't join on, or if it is a selection type (such as and:, :not_all...)
    # @param key [Symbol]
    # @return [True | False]
    def non_join_table_name?(key)
      key.in?(NonJoinTableNames) || selection_type?(key)
    end

    # Does the query condition request the return of a single value?
    def return_value_from_query?
      @this_val_where[:mode] == 'return_value'
    end

    # Does the condition request the return of a list of values?
    def return_value_list_from_query?
      @this_val_where[:mode] == 'return_value_list'
    end

    # Does the condition request the return of the instance as a result?
    def return_result_from_query?
      @this_val_where[:mode] == 'return_result'
    end

    # Does the condition request the return of the instance as a result?
    def return_all_results_from_query?
      @this_val_where[:mode] == 'return_all_results'
    end

    # Logging of results to aid debugging
    def log_results
      return if Rails.env.production?

      begin
        Rails.logger.debug "**#{@orig_cond_type}***********************************************************************"
        Rails.logger.debug "this instance: #{@current_instance.id}"
        Rails.logger.debug "@condition_type: #{@condition_type} - @loop_res: #{@loop_res} - @cond_res: #{@cond_res}" \
                           " - @orig_loop_res: #{@orig_loop_res}"
        Rails.logger.debug @condition_config
        Rails.logger.debug @non_query_conditions&.conditions
        Rails.logger.debug @base_query.to_sql if @base_query
        Rails.logger.debug @condition_scope.to_sql if @condition_scope
        Rails.logger.debug '*******************************************************************************************'
      rescue StandardError => e
        Rails.logger.warn "@condition_type: #{@condition_type} - @loop_res: #{@loop_res} - @cond_res: #{@cond_res}" \
                          " - @orig_loop_res: #{@orig_loop_res}"
        Rails.logger.warn @condition_config
        Rails.logger.warn @join_tables
        Rails.logger.warn JSON.pretty_generate(@action_conf)
        Rails.logger.warn "Failure in calc_actions: #{e}\n#{e.backtrace.join("\n")}"
        raise e
      end
    end
  end
end
