module CalcActions

  extend ActiveSupport::Concern

  include FieldDefaults


  included do
    # We won't use a query join when referring to tables based on these keys
    NonJoinTableNames = [:this, :referring_record, :this_references, :parent_references, :validate].freeze

    SelectionTypes = :all, :any, :not_all, :not_any

    BoolTypeString = '__!BOOL__'.freeze

    UnaryConditions = ['IS NOT NULL', 'IS NULL'].freeze
    BinaryConditions = ['=', '<', '>', '<>', '<=', '>=', 'LIKE', '~'].freeze
    ValidExtraConditions = (BinaryConditions + UnaryConditions).freeze
    ValidExtraConditionsArrays = [
      '= ANY', # The value of this field (must be scalar) matches any value from the retrieved array field
      '<> ANY', # The value of this field (must be scalar) must not match any value from the retrieved array field
      '= ARRAY_LENGTH', # The value of this field (must be integer) equals the length of the retrieved array field
      '<> ARRAY_LENGTH', # The value of this field (must be integer) must not equal the length of the retrieved array field
      '= LENGTH', # The value of this field (must be integer) equals the length of the string (varchar or text) field
      '<> LENGTH', # The value of this field (must be integer) must not equal the length of the string (varchar or text) field
      '&&', # Any value of this field (an array) must be in the retrieved array field
      '@>', # This array field contains all of the elements of the retrieved array field
      '<@' # This array field's elements are all found in the retrieved array field
    ].freeze

    ReturnTypes = ['return_value', 'return_value_list', 'return_result'].freeze

    attr_accessor :condition_scope, :this_val
  end

  private

    # Check if this is a key we won't join on, or if it is a selection type (such as and:, :not_all...)
    # @param key [Symbol]
    # @return [True | False]
    def non_join_table_name? key
       (key.in?(NonJoinTableNames) || is_selection_type(key))
    end

    # Check if the supplied key is a selection type, starting :all, :not_all, :any, :not_any
    # Allow the same selection type to be used multiple times, such as:
    # not_any:
    # not_any_2:
    # not_any_3:
    # @param key [Symbol]
    # @return [True | False]
    def is_selection_type key
      return key if key.in?(SelectionTypes)
      SelectionTypes.select {|st| key.to_s.start_with? st.to_s}.first
    end

    # Primary method to calculate conditions
    def do_calc_action_if

      # A quick return if this is not a hash or it is empty
      return true unless action_conf.is_a?(Hash) && action_conf.first

      # Final result for all selections
      final_res = true

      action_conf.symbolize_keys!

      # Simple conditions to always return
      #   never: true
      #   always: true
      return false if action_conf[:never]
      return true if action_conf[:always]

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

        # Provide the option of configuring as a list of conditions, such as:
        # not_any:
        # - addresses: ...
        # - addresses: ...
        #
        # ...or...
        #
        # not_any:
        #   addresses: ...
        #   player_contacts: ....
        #
        # all of which must meet the condition type
        #
        # Nesting is allowed, which is handled appropriately

        # Save the original key, representing the condition type, such as :not_all_fields_must_match
        orig_cond_type = condition_type

        #If the condition_type key is not a selection type, use the original condition_type
        # value since it represents a table name or other reference item
        condition_type = is_selection_type(condition_type) || condition_type

        # Initialize the loop result, as true for all, not_any, since they AND results,
        # not_all and any OR results, so must be initialized to false
        loop_res = condition_type.in?([:all, :not_any])
        orig_loop_res = loop_res

        # For each condition config definition, run the main tests
        condition_config_array.each do |condition_config|
          @condition_config = condition_config

          # Check if the first key is a selection type. If it is, wrap it in a
          # {this: original hash} to make it easier to process consistently
          if is_selection_type(@condition_config.first.first)
            @condition_config = {this: @condition_config}
          end

          # Calculate the base query and conditions to use later
          calc_base_query condition_type

          #### :all ####
          if condition_type == :all
            cond_res = true
            res_q = true
            # equivalent of (cond1 AND cond2 AND cond3 ...)
            # These conditions are easy to handle as a standard query
            # @this_val_where check allows a return_value definition to be used alone without other conditions
            unless @condition_values.empty? && @extra_conditions.empty? && !@this_val_where
              gen_condition_scope_and_return_value @condition_values, @extra_conditions
              res_q = calc_query_conditions
              merge_failures({condition_type => @condition_config}) if !res_q
            end

            @non_query_conditions.each do |table, fields|
              fields.each do |field_name, expected_val|
                res_q &&= calc_non_query_condition(table, field_name, expected_val)
                merge_failures({condition_type => {table => {field_name => expected_val}}}) if !res_q
              end
            end

            cond_res &&= !!res_q
            loop_res &&= cond_res

          #### :not_all ####
          elsif condition_type == :not_all
            cond_res = true
            res_q = true
            # equivalent of NOT(cond1 AND cond2 AND cond3 ...)
            unless @condition_values.empty? && @extra_conditions.empty?
              gen_condition_scope_and_return_value @condition_values, @extra_conditions
              res_q = calc_query_conditions
            end

            @non_query_conditions.each do |table, fields|
              fields.each do |field_name, expected_val|
                res_q &&= calc_non_query_condition(table, field_name, expected_val)
              end
            end

            cond_res &&= !res_q

            # Not all matches - return all possible items that failed
            merge_failures({condition_type => @condition_values}) if !cond_res
            merge_failures({condition_type => @non_query_conditions}) if !cond_res

            loop_res ||= cond_res

          #### :any ####
          elsif condition_type == :any

            raise FphsException.new "@extra_conditions not supported with any / not_any conditions" unless @extra_conditions.empty?

            cond_res = false
            res_q = false
            # equivalent of (cond1 OR cond2 OR cond3 ...)

            if @condition_values.empty?
              # Reset the previous condition_scope, since it could be carrying unwanted joins from an all, not_any condition
              @condition_scope = nil
              reset_scope = nil
            else

              @condition_values.each do |table, fields|
                fields.each do |field_name, expected_val|
                  gen_condition_scope_and_return_value({table => {field_name => expected_val}}, @extra_conditions, 'OR')
                  res_q = (@condition_scope.length > 0)

                  break if res_q
                end
                break if res_q
              end

              reset_scope = @base_query.order(id: :desc).limit(1)
            end

            # Reset the condition scope, since gen_condition_scope_and_return_value will have messed with it
            @condition_scope = reset_scope
            unless res_q || @condition_scope.nil?
              res_q ||= calc_query_conditions return_first_false: false
            end

            # If no matches - return all possible items that failed
            merge_failures({condition_type => @condition_values}) if !res_q

            unless res_q
              @non_query_conditions.each do |table, fields|
                fields.each do |field_name, expected_val|
                  res_q ||= calc_non_query_condition(table, field_name, expected_val)
                  break if res_q
                end
              end
            end

            merge_failures({condition_type => @non_query_conditions}) if !res_q

            cond_res = res_q
            loop_res ||= cond_res

          #### :not_any ####
          elsif condition_type == :not_any

            raise FphsException.new "@extra_conditions not supported with any / not_any conditions" unless @extra_conditions.empty?

            cond_res = true
            # equivalent of NOT(cond1 OR cond2 OR cond3 ...)
            # also equivalent to  (NOT(cond1) AND NOT(cond2) AND NOT(cond3))

            if @condition_values.empty?
              # Reset the previous condition_scope, since it could be carrying unwanted joins from an all, not_any condition
              @condition_scope = nil
            else

              @condition_values.each do |table, fields|
                fields.each do |field_name, expected_val|
                  gen_condition_scope_and_return_value({table => {field_name => expected_val}}, @extra_conditions, 'OR')
                  res_q = calc_query_conditions
                  merge_failures({condition_type => {table => {field_name => expected_val}}}) if res_q
                  cond_res &&= !res_q
                  break unless cond_res && !return_failures
                end
                break unless cond_res && !return_failures
              end

            end

            @non_query_conditions.each do |table, fields|
              fields.each do |field_name, expected_val|

                res_q = !calc_non_query_condition(table, field_name, expected_val)
                merge_failures({condition_type => {table => {field_name => expected_val}}}) if !res_q
                cond_res &&= res_q
              end
            end

            loop_res &&= cond_res
          else
            raise FphsException.new "Incorrect condition type specified when calculating action if: #{condition_type}"
          end

          log_results orig_cond_type, condition_type, loop_res, cond_res, orig_loop_res

          # We can end the loop, unless the last result was a success
          break unless loop_res

        end

        final_res &&= loop_res
        break unless final_res
      end

      # Return the final result
      !!final_res
    end

    # For validation, we need to know what failed. Merge the failures from multiple different tests
    # @param results [Hash] The results to be merged follow this format:
    #   {
    #     condition_type => {
    #       table => {
    #         field_name => expected_val
    #       }
    #     }
    #   }
    def merge_failures results
      if return_failures && !@skip_merge
        results.first.last.each do |t, res|
          if res.is_a?(Hash) && res.first.last && res.first.last.first.first == :validate
            field = res.first.first
            results.first.last[t] = {field => new_validator(res.first.last[:validate].first.first, nil, options: {}).message }
          end
        end
        return_failures.deep_merge!(results)
      end
    end

    # Generate the query for the @condition_scope.
    # This basically generates the query that will be used to handle queries against tables, and
    # acts as the scope around individual non query conditions
    # As a side-effect, also get the return_value, return_value_list or return_result in @this_val
    # @param conditions [Hash] conditions as a standard ActiveQuery hash {table: {field: value}, ...}
    # @param extra_conditions [Array]
    # @return [ActiveQuery::Relation] the final @condition_scope
    def gen_condition_scope_and_return_value conditions, extra_conditions = [], bool = 'AND'

      unless conditions.first && conditions.first.last&.length == 0
        # Conditions are available - apply them as a where clause on top of the base query
        @condition_scope = @base_query.where(conditions)
      else
        # If no conditions are specified for this table, don't apply it as a where clause
        # since it always invalidates the query
        # This typically happens as a result of extra_conditions being applied to non query conditions,
        # (references such as this, this_references etc being the key name, rather than a table)
        @condition_scope = @base_query
      end

      # For extra_conditions related to non query conditions, apply them directly
      if extra_conditions.length > 1
        # Handle replacement of AND or OR into the generated query conditions SQL
        extra_conditions[0].gsub(BoolTypeString, bool)
        @condition_scope = @condition_scope.where(extra_conditions)
      end

      # Handle the return of requested values, lists or results (instances) if the definition
      # requested this
      if @this_val_where
        # The condition scope must be ordered in reverse, as always, and if we
        # only are requesting a single result then limit 1, otherwise get all results for the list
        cs = @condition_scope.order(id: :desc)
        cs = cs.limit(1) if return_value_from_query? || return_result_from_query?
        first_cond_res = cs.first

        # If a result was found process the returns, otherwise continue
        if first_cond_res

          # The instance @condition_scope can reflect the successful query scope
          @condition_scope = cs

          # The result instance now gets the defined association
          # TODO: check this against a list of valid associations
          all_res = @this_val = first_cond_res.send(@this_val_where[:assoc])
          first_res = all_res.first

          # If we got a result from the asssociation process it, otherwise continue
          if first_res

            # The table name for the result we need
            tn = first_res.class.table_name
            # The field to return, checked by matching the defined field name against the attributes of the class
            fn = first_res.class.attribute_names.select{|s| s == @this_val_where[:field_name].to_s}.first
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
              @this_val = first_res.class.find(rquery.first.id)
            else
              # Run the results query and get either a single result or a list
              rvals = rquery.pluck("#{tn}.#{fn}")
              @this_val = rvals.first if return_value_from_query?
              @this_val = rvals if return_value_list_from_query?
            end
          end
        end
      else
        @condition_scope = @condition_scope.order(id: :desc).limit(1)
      end

      # Return the usable @condition_scope
      @condition_scope

    end

    # Calculate non query condition results and nested conditions, comparing against expected values
    # Multiple expected values may be specified, typically where a nested condition is defined
    #
    def calc_non_query_condition table, field_name, expected_vals
      @skip_merge = false
      # this_val attribute is used to return the last value from a definition. Used for simple lookups

      res = true
      # Allow a list of possible conditions to be used
      expected_vals = [expected_vals] unless expected_vals.is_a?(Array) && expected_vals.first.is_a?(Hash)

      expected_vals.each do |expected_val|


        if field_name == :return_constant
          # The literal value specified will be returned
          # some_table:
          #   return_constant: value to return
          @this_val = expected_val
          return true
        end

        #### If we have a non-query table specified
        if table == :this || table == :parent || table == :referring_record || (table == :user && field_name != :role_name)

          # Pick the instance we are referring to
          if table == :this
            in_instance = current_instance
          elsif table == :user
            in_instance = @current_instance.master.current_user
          elsif table == :parent
            in_instance = current_instance.parent_item
          elsif table == :referring_record
            in_instance = current_instance.referring_record
          end

          if field_name == :exists
            # Simply get a true result if instance found and {exists: true} or
            # instance not found and {exists: false}
            res = @this_val = (!!expected_val == !!in_instance)
            @skip_merge = true

          elsif !in_instance
            # We failed to find the instance we need to continue.
            raise FphsException.new "Instance not found for #{table}"
          else

            if expected_val.is_a?(Hash)
              ## An expected value hash may mean several things, including
              # field (not just equals) conditions, validations and nested conditions

              # If this is a field condition (something other than equals), set it up to be calculated
              # Generate a query that references the in_instance object through its association,
              # specifying the id as an expected value, plus the condition to be calculated within the query
              # This forces us to run this as a nested condition.
              if expected_val[:condition]
                assoc_name = ModelReference.record_type_to_ns_table_name(in_instance).pluralize.to_sym
                expected_val = { assoc_name => { field_name => expected_val, id: in_instance.id } }
                field_name = :all
              end

              if is_selection_type field_name
                #### Handle a Nested Condition
                # If we have the field name key being all, any, etc, then run the nested conditions
                # with the current condition scope
                ca = ConditionalActions.new({field_name => expected_val}, in_instance, current_scope: @condition_scope, return_failures: return_failures)
                res &&= ca.calc_action_if

                # Handle a return value if one was not already set
                @this_val ||= ca.this_val
                @skip_merge = true

              elsif expected_val.keys.first == :validate
                #### Handle validate
                # take the validate definition and calculate the result
                res &&= calc_complex_validation expected_val[:validate], in_instance.attributes[field_name.to_s]

              else
                #### Something was wrong in the definition
                raise FphsException.new <<EOF
calc_non_query_condition field is not a selection type or :validate hash. Ensure you have an all, any, not_any, not_all before all nested expressions.

#{@condition_config.to_yaml}
EOF
              end


            else
              ## The expected value was not a hash.
              # Simply handle the comparison, and return a value or result instance if requested

              # Get the value
              this_val = in_instance.attributes[field_name.to_s]
              if expected_val.is_a? Array
                # Since we have expected value as an array, simply see if it includes the value we found
                res &&= expected_val.include?(this_val)
              else
                # Simply compare the expected value against the one we found
                res &&= this_val == expected_val
              end

              # Handle return value or result
              if expected_value_requests_return? :value, expected_val
                @this_val = this_val
              elsif expected_value_requests_return? :result, expected_val
                @this_val = in_instance
              end

            end

          end


        #### If we have a user or role_name as the table key
        elsif table == :user && field_name == :role_name
          user = @current_instance.master.current_user
          expected_val = [expected_val] unless expected_val.is_a? Array

          role_names = user.user_roles.active.pluck(:role_name)
          @this_val = role_names if expected_value_requests_return? :value, expected_val
          role_res = false
          expected_val.each do |e|
            role_res ||= role_names.include? e
          end
          res &&= role_res

        end

        #### Any other table keys are just ignored

      end

      # Return the result
      res

    end

    # Generate query conditions and a list of join tables based on a conditional configuration,
    # such as
    # creatable_if:
    #  all:
    #    <creatable conditions>
    #
    def calc_base_query condition_type

      # join_tables = @condition_config.keys.map(&:to_sym) - SelectionTypes
      join_tables = []
      @condition_values = {}
      @extra_conditions = []
      @non_query_conditions = {}
      @sub_conditions = {}

      @condition_config.each do |c_table, t_conds|
        join_table_name = c_table.to_sym
        table_name = ModelReference.record_type_to_table_name(c_table).to_sym

        if is_selection_type(table_name)
          # Nested conditions are ignored, since they are
          # handled directly in the condition processing logic

        else

          t_conds.each do |field_name, val|

            # non query conditions are those aren't formulated with a series of
            # inner joins on the master. They are handled as individual queries.

            non_query_condition = table_name.in?([:this, :user, :parent, :referring_record])
            if field_name == :return_constant
              # Allow us to return a set value, typically if no other conditions are met
              # This is a non query condition
              non_query_condition = true

            elsif val.is_a? Hash
              # If the conditional value is actually a hash, then we need to
              # get the value to be matched from another record

              val_item_key = val.first.first

              # If a specific table was not set (we have a select type such as all, any)
              # then we can assume that we are referring to 'this' current record
              if is_selection_type(val_item_key)
                val_item_key = :this
                val = {this: val}
              end


              if val_item_key == :this && !val.first.last.is_a?(Hash)
                # Get a literal value from 'this' to be compared
                val = @current_instance.attributes[val.first.last]
              elsif val_item_key == :parent && !val.first.last.is_a?(Hash)
                # Get a literal value from the current instance's parent to be compared
                val = @current_instance.parent_item.attributes[val.first.last]
              elsif val_item_key == :referring_record && !val.first.last.is_a?(Hash)
                # Get a literal value from the current instance's referring_record.
                # This is a record referring to the current instance.
                # A referring record is either based on the context of the current request (from a controller)
                # or if there is only a single model reference referring to the current instance,
                # that is used instead
                val = @current_instance.referring_record && @current_instance.referring_record.attributes[val.first.last]
              elsif val_item_key == :this_references
                if val.first.last.is_a?(Hash)
                  att = val.first.last.first.last
                  to_table_name = val.first.last.first.first
                  val = []
                  model_refs = @current_instance.model_references(active_only: true)
                  model_refs = model_refs.select {|r| r.to_record_type == to_table_name.to_s.singularize.ns_camelize}

                  model_refs.each do |mr|
                    val << mr.to_record.attributes[att]
                  end

                else
                  att = val.first.last
                  # non_query_condition = true
                  val = []

                  mrs = @current_instance.model_references(active_only: true)

                  unless non_join_table_name?(join_table_name)
                    mrs = mrs.select {|r| r.to_record_type == join_table_name.to_s.singularize.ns_camelize}
                  end

                  # Get the specified attribute's value from each of the model references
                  # Generate an array, allowing the conditions to be IN any of these
                  mrs.each do |mr|
                    val << mr.to_record.attributes[att]
                  end
                end
              elsif val_item_key == :parent_references
                if val.first.last.is_a?(Hash)
                  att = val.first.last.first.last
                  to_table_name = val.first.last.first.first
                  val = []
                  raise FphsException.new "No referring record specified when using parent_references" unless @current_instance.referring_record
                  parent_model_refs = @current_instance.referring_record.model_references(active_only: true)
                  parent_model_refs = parent_model_refs.select {|r| r.to_record_type == to_table_name.to_s.singularize.ns_camelize}

                  parent_model_refs.each do |mr|
                    val << mr.to_record.attributes[att]
                  end

                else
                  att = val.first.last
                  # non_query_condition = true
                  val = []

                  # Get the specified attribute's value from each of the parent model references
                  # Generate an array, allowing the conditions to be IN any of these
                  # parent_model = ModelReference.find_where_referenced_from(@current_instance).order(id: :desc).first
                  parent_model_refs = @current_instance.referring_record.model_references(active_only: true)

                  unless non_join_table_name?(join_table_name)
                    parent_model_refs = parent_model_refs.select {|r| r.to_record_type == join_table_name.to_s.singularize.ns_camelize}
                  end

                  parent_model_refs.each do |mr|
                    val << mr.to_record.attributes[att]
                  end
                end
              elsif val_item_key == :user
                att = val.first.last
                user = @current_instance.master.current_user
                if att.is_a?(Hash)
                  if att == :role_name
                    role_names = user.user_roles.active.pluck(:role_name)
                    val = role_names
                  else
                  end
                else
                  val = user.attributes[att]
                end

              else
                val.keys.each do |val_key|
                  if non_join_table_name?(val_key)
                    non_query_condition = true
                  else
                    join_tables << val_key unless join_tables.include? val_key
                  end
                end
              end
            end
            unless non_query_condition
              if val.is_a?(Hash) && val[:condition].in?(ValidExtraConditions)
                if @extra_conditions[0].blank?
                  @extra_conditions[0] = ""
                else
                  @extra_conditions[0] += " #{BoolTypeString} "
                end

                if val[:condition].in? UnaryConditions
                  @extra_conditions[0] += "#{table_name}.#{field_name} #{val[:condition]}"
                else

                  vc = ValidExtraConditions.find {|c| c == val[:condition]}
                  vv = dynamic_value(val[:value])

                  @extra_conditions[0] += "#{table_name}.#{field_name} #{vc} (?)"
                  @extra_conditions << vv
                end
              elsif val.is_a?(Hash) && val[:condition].in?(ValidExtraConditionsArrays)
                  veca_extra_args = ''
                  if @extra_conditions[0].blank?
                    @extra_conditions[0] = ""
                  else
                    @extra_conditions[0] += " #{BoolTypeString} "
                  end

                  vc = ValidExtraConditionsArrays.find {|c| c == val[:condition]}
                  vv = dynamic_value(val[:value])

                  negate = (val[:not] ? 'NOT' : '')

                  leftop = '?'
                  if vc == '&&'
                    leftop = "ARRAY[?]"
                    if vv.first.is_a? String
                      leftop += "::varchar[]"
                    end
                  end



                  veca_extra_args = ', 1' if vc.include?('ARRAY_LENGTH')

                  @extra_conditions[0] += "#{negate} (#{leftop} #{vc} (#{table_name}.#{field_name}#{veca_extra_args}))"
                  @extra_conditions << vv
              else

                # Check if the definition expects a return value, list or result
                mode = nil
                if expected_value_requests_return? :value, val
                  mode = 'return_value'
                elsif expected_value_requests_return? :result, val
                  mode = 'return_result'
                elsif expected_value_requests_return? :value_list, val
                  mode = 'return_value_list'
                end

                # If a return mode was specified, set this up to be used in the query
                if mode
                  @this_val_where = {
                    assoc: c_table.to_sym,
                    field_name: field_name,
                    table_name: ModelReference.record_type_to_ns_table_name(c_table).to_sym,
                    mode: mode
                  }
                end

                # Add a condition value for the query, except if the expected value is requesting a return, with "return_*"
                # (not return_* in an array though, since this is part of an IN statement)
                unless val.in?(ReturnTypes)
                  @condition_values[table_name] ||= {}
                  @condition_values[table_name][field_name] = dynamic_value(val)
                end

              end
              join_tables << join_table_name unless join_tables.include? table_name
            else
              @non_query_conditions[table_name] ||= {}
              @non_query_conditions[table_name][field_name] = val
            end
          end
        end
      end
      @join_tables = join_tables = (join_tables - [:this, :parent, :referring_record, :this_references, :parent_references, :user, :master, :condition, :value, :hide_error]).uniq

      if [:all, :not_all].include? condition_type
        @base_query = @current_scope.joins(join_tables)
      else
        @base_query = @current_scope.includes(join_tables)
      end
    end

    # Create a dynamic value if the condition's value matches certain strings
    def dynamic_value val, type=nil
      FieldDefaults.calculate_default(current_instance, val, type)
    end

    # Calculate the sub conditions for this level if it contains any of the selection types
    def calc_query_conditions return_first_false: true

      res = return_first_false

      # The query didn't return a result - therefore the condition evaluates to false
      return false if @condition_scope.length == 0



      # Combine sub condition results if they are specified
      @condition_config.each do |c_type, t_conds|
        # If this is a sub condition (the key is one of :all, :any, :not_any, :not_all)
        # go ahead and calculate the sub conditions results by instantiating a ConditionalActions class
        # with the scope as the current condition scope from the query
        st = is_selection_type c_type
        if st
          ca = ConditionalActions.new({c_type => t_conds}, current_instance, current_scope: @condition_scope, return_failures: return_failures)
          res_a = ca.calc_action_if

          if return_first_false
            res &&= res_a
            return unless res
          else
            res ||= res_a
          end

          @this_val ||= ca.this_val
        end
      end

      return res
    end



    def calc_complex_validation condition, value
      res = true
      condition.each do |k, opts|

        v = new_validator k, value, options:{k=>opts}
        test_res = v.value_is_valid? value, current_instance
        res &&= test_res
      end

      res
    end

    def new_validator k, value, options: {}
      validator_class(k).new options.merge(attributes: {_attr: value})
    end

    def validator_class k
      Validates.const_get("#{k.to_s.classify}Validator")
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

    # Does the condition contain a return_value or return_result string
    # @param type [Symbol | String] :value or :result indicating whether the request wants
    #   a result value or an instance returned
    # @param condition [String | Array] the condition to test
    # @return [True | False]
    def expected_value_requests_return? type, condition
      ret_type = "return_#{type}"
      condition == ret_type || condition.is_a?(Array) && condition.include?(ret_type)
    end

    # Logging of results to aid debugging
    def log_results orig_cond_type, condition_type, loop_res, cond_res, orig_loop_res
      unless Rails.env.production?
        begin
          Rails.logger.debug "**#{orig_cond_type}*******************************************************************************************************"
          Rails.logger.debug "condition_type: #{condition_type} - loop_res: #{loop_res} - cond_res: #{cond_res} - orig_loop_res: #{orig_loop_res}"
          Rails.logger.debug @condition_config
          Rails.logger.debug @non_query_conditions
          Rails.logger.debug @base_query.to_sql if @base_query
          Rails.logger.debug @condition_scope.to_sql if @condition_scope
          Rails.logger.debug "*********************************************************************************************************"
        rescue => e
          Rails.logger.warn "condition_type: #{condition_type} - loop_res: #{loop_res} - cond_res: #{cond_res} - orig_loop_res: #{orig_loop_res}"
          Rails.logger.warn @condition_config
          Rails.logger.warn @join_tables
          Rails.logger.warn JSON.pretty_generate(@action_conf)
          Rails.logger.warn "Failure in calc_actions: #{e}\n#{e.backtrace.join("\n")}"
          raise e
        end
      end
    end

end
