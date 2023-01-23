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
  extend ActiveSupport::Concern

  include FieldDefaults

  # We won't use a query join when referring to tables based on these keys
  NonJoinTableNames = %i[this parent referring_record top_referring_record this_references parent_references
                         parent_or_this_references user master condition value hide_error role_name reference].freeze
  NonQueryTableNames = %i[this user parent referring_record top_referring_record role_name reference].freeze
  NonQueryNestedKeyNames = %i[this referring_record top_referring_record this_references parent_references
                              parent_or_this_references reference validate].freeze

  SelectionTypes = %i[all any not_all not_any].freeze

  BoolTypeString = '__!BOOL__'

  UnaryConditions = ['IS NOT NULL', 'IS NULL'].freeze
  BinaryConditions = ['=', '<', '>', '<>', '<=', '>=', 'LIKE', '~'].freeze
  ValidExtraConditions = (BinaryConditions + UnaryConditions).freeze
  ValidExtraConditionsArrays = [
    '= ANY', # The value of this field (must be scalar) matches any value from the retrieved array field
    '= ANY REV', # Reverse the operator order
    '<> ANY', # The value of this field (must be scalar) must not match any value from the retrieved array field
    '<> ANY REV', # Reverse the operator order
    '= ARRAY_LENGTH', # The value of this field (must be integer) equals the length of the retrieved array field
    '<> ARRAY_LENGTH', # The value of this field (must be integer) must not equal length of the retrieved array field
    '= LENGTH', # The value of this field (must be integer) equals the length of the string (varchar or text) field
    '<> LENGTH', # The value of this field (must be integer) must not equal length of the string (varchar/text) field
    '&&', # There is an overlap, so any value of this field (an array) must be in the retrieved array field
    '@>', # This array field contains all of the elements of the retrieved array field
    '<@' # This array field's elements are all found in the retrieved array field
  ].freeze

  ReturnTypes = %w[return_value return_value_list return_result].freeze

  included do
    attr_accessor :condition_scope, :this_val
  end

  private

  # Primary method to calculate conditions
  def do_calc_action_if
    # A quick return if this is not a hash or it is empty
    return true unless action_conf.is_a?(Hash) && action_conf.first

    # Final result for all selections
    final_res = true

    self.action_conf = action_conf.symbolize_keys

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

      # If the condition_type key is not a selection type, use the original condition_type
      # value since it represents a table name or other reference item
      condition_type = is_selection_type(condition_type) || condition_type

      # Initialize the loop result, as true for all, not_any, since they AND results,
      # not_all and any OR results, so must be initialized to false
      loop_res = condition_type.in?(%i[all not_any])
      orig_loop_res = loop_res

      # For each condition config definition, run the main tests
      condition_config_array.each do |condition_config|
        @condition_config = condition_config

        # Check if the first key is a selection type. If it is, wrap it in a
        # {this: original hash} to make it easier to process consistently
        @condition_config = { this: @condition_config } if is_selection_type(@condition_config.first.first)

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
            gen_condition_scope @condition_values, @extra_conditions
            calc_return_types
            res_q = calc_nested_query_conditions
            merge_failures(condition_type => @condition_config) unless res_q
          end

          @non_query_conditions.each do |table, fields|
            fields.each do |field_name, expected_val|
              res_q &&= calc_non_query_condition(table, field_name, expected_val)
              merge_failures(condition_type => { table => { field_name => expected_val } }) unless res_q
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
            gen_condition_scope @condition_values, @extra_conditions
            calc_return_types
            res_q = calc_nested_query_conditions
          end

          @non_query_conditions.each do |table, fields|
            fields.each do |field_name, expected_val|
              res_q &&= calc_non_query_condition(table, field_name, expected_val)
            end
          end

          cond_res &&= !res_q

          # Not all matches - return all possible items that failed
          merge_failures(condition_type => @condition_values) unless cond_res
          merge_failures(condition_type => @non_query_conditions) unless cond_res

          loop_res ||= cond_res

        #### :any ####
        elsif condition_type == :any

          unless @extra_conditions.empty?
            raise FphsException, '@extra_conditions not supported with any / not_any conditions'
          end

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
                gen_condition_scope({ table => { field_name => expected_val } }, @extra_conditions, 'OR')
                calc_return_types
                res_q = !@condition_scope.empty?

                break if res_q
              end
              break if res_q
            end

            reset_scope = @base_query.order(id: :desc).limit(1)
          end

          # Reset the condition scope, since gen_condition_scope will have messed with it
          @condition_scope = reset_scope
          res_q ||= calc_nested_query_conditions return_first_false: false unless res_q || @condition_scope.nil?

          # If no matches - return all possible items that failed
          merge_failures(condition_type => @condition_values) unless res_q

          unless res_q
            @non_query_conditions.each do |table, fields|
              fields.each do |field_name, expected_val|
                res_q ||= calc_non_query_condition(table, field_name, expected_val)
                break if res_q
              end
            end
          end

          merge_failures(condition_type => @non_query_conditions) unless res_q

          cond_res = res_q
          loop_res ||= cond_res

        #### :not_any ####
        elsif condition_type == :not_any

          unless @extra_conditions.empty?
            raise FphsException, '@extra_conditions not supported with any / not_any conditions'
          end

          cond_res = true
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
                res_q = !@condition_scope.empty?
                merge_failures(condition_type => { table => { field_name => expected_val } }) if res_q
                cond_res &&= !res_q
                break unless cond_res && !return_failures
              end
              break unless cond_res && !return_failures
            end

            reset_scope = @base_query.order(id: :desc).limit(1)
          end

          # Reset the condition scope, since gen_condition_scope will have messed with it
          @condition_scope = reset_scope
          if cond_res && !@condition_scope.nil?
            res_q = calc_nested_query_conditions return_first_false: false
            cond_res &&= !res_q
          end

          @non_query_conditions.each do |table, fields|
            fields.each do |field_name, expected_val|
              res_q = !calc_non_query_condition(table, field_name, expected_val)
              merge_failures(condition_type => { table => { field_name => expected_val } }) unless res_q
              cond_res &&= res_q
            end
          end

          loop_res &&= cond_res
        else
          raise FphsException, "Incorrect condition type specified when calculating action if: #{condition_type}"
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
  def merge_failures(results)
    return unless return_failures && !@skip_merge

    results.first.last.each do |t, res|
      next unless res.is_a?(Hash) && res.first&.last&.first&.first == :validate

      field = res.first.first
      results.first.last[t] =
        { field => new_validator(res.first.last[:validate].first.first, nil, options: {}).message }
    end
    return_failures.deep_merge!(results)
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
                         # This typically happens as a result of extra_conditions being applied to non query conditions,
                         # (references such as this, this_references etc being the key name, rather than a table)
                         @base_query
                       else
                         # Conditions are available - apply them as a where clause on top of the base query
                         @base_query.where(conditions)
                       end

    # For extra_conditions related to non query conditions, apply them directly
    if extra_conditions.present? && extra_conditions[0]&.strip&.present?
      # Handle replacement of AND or OR into the generated query conditions SQL
      extra_conditions[0].gsub(BoolTypeString, bool)
      @condition_scope = @condition_scope.where(extra_conditions)
    end

    @condition_scope = @condition_scope.order(id: :desc).limit(1) unless @this_val_where

    # Return the usable @condition_scope
    @condition_scope
  end

  # Get any requested return_value, return_value_list or return_result
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
    cs = cs.limit(1) if return_value_from_query? || return_result_from_query?
    first_cond_res = cs.first

    # If a result was found process the returns, otherwise continue
    return unless first_cond_res

    # The instance @condition_scope can reflect the successful query scope
    @condition_scope = cs

    # The result instance now gets the defined association
    # TODO: check this against a list of valid associations
    all_res = @this_val = if first_cond_res.respond_to?(@this_val_where[:assoc])
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
      @this_val = first_res.class.find(rquery.first.id)
    else
      # Run the results query and get either a single result or a list
      rvals = rquery.pluck("#{tn}.#{fn}")
      @this_val = rvals.first if return_value_from_query?
      @this_val = rvals if return_value_list_from_query?
    end
  end

  # Calculate non query condition results and nested conditions, comparing against expected values
  # Multiple expected values may be specified, typically where a nested condition is defined
  #
  def calc_non_query_condition(table, field_name, expected_vals)
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
      if table.in?(%i[this parent referring_record top_referring_record reference]) ||
         (table == :user && field_name != :role_name)

        # Pick the instance we are referring to
        case table
        when :this
          in_instance = current_instance
        when :user
          in_instance = @current_instance.current_user
        when :parent
          in_instance = current_instance.parent_item
        when :referring_record
          in_instance = current_instance.referring_record
        when :top_referring_record
          in_instance = current_instance.top_referring_record
        when :reference
          in_instance = current_instance.reference
        end

        if field_name == :exists
          # Simply get a true result if instance found and {exists: true} or
          # instance not found and {exists: false}
          res = @this_val = (!!expected_val == !!in_instance)
          @skip_merge = true

        elsif !in_instance
          # We failed to find the instance we need to continue.
          raise FphsException, "Instance not found for #{table}"
        elsif expected_val.is_a?(Hash)

          if expected_val[:condition]
            assoc_name = ModelReference.record_type_to_assoc_sym(in_instance)
            expected_val = { assoc_name => { field_name => expected_val, id: in_instance.id } }
            field_name = :all
          end

          if is_selection_type field_name
            #### Handle a Nested Condition
            # If we have the field name key being all, any, etc, then run the nested conditions
            # with the current condition scope
            ca = ConditionalActions.new({ field_name => expected_val }, in_instance,
                                        current_scope: @condition_scope, return_failures: return_failures)
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
            raise FphsException, <<~ERROR_MSG
              calc_non_query_condition field is not a selection type or :validate hash. Ensure you have an all, any, not_any, not_all before all nested expressions.

              #{@condition_config.to_yaml}
            ERROR_MSG
          end
        ## An expected value hash may mean several things, including
        # field (not just equals) conditions, validations and nested conditions

        # If this is a field condition (something other than equals), set it up to be calculated
        # Generate a query that references the in_instance object through its association,
        # specifying the id as an expected value, plus the condition to be calculated within the query
        # This forces us to run this as a nested condition.

        else
          ## The expected value was not a hash.
          # Simply handle the comparison, and return a value or result instance if requested

          # Get the value
          this_val = attribute_from_instance(in_instance, field_name)

          res &&= if expected_val.is_a? Array
                    # Since we have expected value as an array, simply see if it includes the value we found
                    expected_val.include?(this_val)
                  else
                    # Simply compare the expected value against the one we found
                    this_val == expected_val
                  end

          # Handle return value or result
          if expected_value_requests_return? :value, expected_val
            @this_val = this_val
          elsif expected_value_requests_return? :result, expected_val
            @this_val = in_instance
          end

        end

      #### If we have a user as the table key and we are requesting the role_name
      # to match the expected value
      elsif table == :user && field_name == :role_name
        user = @current_instance.current_user
        raise FphsException, 'Current user not set when specifying evaluation if user.role_name' unless user

        expected_val = [expected_val] unless expected_val.is_a? Array

        role_names = user.role_names
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

  #
  # Get an attribute from an instance, and ensure that a blank is
  # converted to nil if the type is not a string
  # If the attribute name starts with 'previous_value_of_' and the result
  # was not returned from the current attribute values, attempt to get the
  # result from the model's #previous_changes hash of changes.
  # @param [UserBase] from_instance
  # @param [String|Symbol] attr_name
  # @return [Object] resulting value
  def attribute_from_instance(from_instance, attr_name)
    val = from_instance.attributes[attr_name.to_s]
    if val.blank? && attr_name.to_s.start_with?('previous_value_of_') && from_instance.respond_to?(:previous_changes)
      real_attr_name = attr_name.to_s.sub(/^previous_value_of_/, '')
      val = from_instance.previous_changes[real_attr_name]&.first
    end

    attr_type = from_instance.type_for_attribute(attr_name).type
    val = nil if val.blank? && attr_type != :string
    val = false if val.nil? && attr_type == :boolean
    val
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
  # @param ref_table_name [String | Symbol] the table name to reference in this_references / parent_references conditions
  # @return [String | Number | Array] return val to be matched
  def generate_match_query_condition(val, ref_table_name)
    val_item_key = val.first.first
    val_item_value = val.first.last

    # If a specific table was not set (we have a select type such as all, any)
    # then we can assume that we are referring to 'this' current record
    if is_selection_type(val_item_key)
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

    elsif val_item_key.in? %i[this_references parent_references parent_or_this_references]
      # Get possible values from records referenced by this instance, or this instance's referring record (parent)

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
        model_refs.each do |mr|
          val << mr.to_record.attributes[att]
        end
      end

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

      val = if att == 'role_name'
              # The value to match against is an array of the user's role names
              user.role_names
            else
              # The value to match against is the value of the specified attribute
              user.attributes[att]
            end

    end

    val
  end

  # Based on match query conditions being generated, now setup the value comparisons.
  # This may produce extra conditions to be pushed into the query at runtime, or
  # basic joined conditions.
  def generate_query_condition_values(val, table_name, field_name, _join_table_name)
    if val.is_a?(Hash)

      condition_type = val[:condition]

      # If we have a non-equals condition specified, generate the extra conditions
      if condition_type.in?(ValidExtraConditions)
        # A simple unary or binary condition

        # Setup the query conditions array ["sql", cond1, cond2, ...]
        if @extra_conditions[0].blank?
          @extra_conditions[0] = ''
        else
          @extra_conditions[0] += " #{BoolTypeString} "
        end

        if condition_type.in? UnaryConditions
          # It is a unary condition, extend the SQL
          @extra_conditions[0] += "#{table_name}.#{field_name} #{condition_type}"
        else
          # It is a binary condition, extend the SQL and conditions
          vc = ValidExtraConditions.find { |c| c == condition_type }
          vv = dynamic_value(val[:value])
          @extra_conditions[0] += "#{table_name}.#{field_name} #{vc} (?)"
          @extra_conditions << vv
        end

      elsif condition_type.in?(ValidExtraConditionsArrays)
        # It is an array condition

        veca_extra_args = ''

        # Setup the query conditions array ["sql", cond1, cond2, ...]
        if @extra_conditions[0].blank?
          @extra_conditions[0] = ''
        else
          @extra_conditions[0] += " #{BoolTypeString} "
        end

        # Extend the SQL and conditions
        vc = ValidExtraConditionsArrays.find { |c| c == condition_type }

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
      end

    end

    return unless !condition_type && !val.in?(ReturnTypes)

    @condition_values[table_name] ||= {}
    val = val.reject { |r| r.in?(ReturnTypes) } if val.is_a?(Array)
    @condition_values[table_name][field_name] = dynamic_value(val)
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
    end

    # If a return mode was specified, set this up to be used in the query
    return unless mode

    @this_val_where = {
      assoc: join_table_name,
      field_name: field_name,
      table_name: ModelReference.record_type_to_ns_table_name(join_table_name).to_sym,
      mode: mode
    }
  end

  # Generate query conditions to support the conditional configuration.
  # Each condition definition decides if it is a query or non-query condition and
  # sets up conditions to support this.
  # Query conditions may incorporate joined tables (inner and left joins) into the query
  # as well as formulating the ActiveRecord queries to support this.
  # Non-query conditions build on the base query when evaluated, and this method just
  # sets up some structures to support this.
  def calc_base_query(condition_type)
    @join_tables = []
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
          non_query_condition = is_non_query_condition table_name, field_name, val

          if val.is_a?(Hash)
            # Since the conditional value is actually a hash, we need to
            # get the value to be matched from another referenced record (or this)
            # Generate the query condition to do this
            val = generate_match_query_condition(val, join_table_name)
          end

          if non_query_condition
            # We have decided this is a non query condition, and will not be joined on the master
            # Set this so they can be evaluated at runtime.
            @non_query_conditions[table_name] ||= {}
            @non_query_conditions[table_name][field_name] = val
          else
            # We have finally decided that this is a regular query condition
            # Handle setting up the condition values
            generate_query_condition_values(val, table_name, field_name, join_table_name)

            # And handle any returns value / results config
            generate_returns_config(val, join_table_name, field_name)

            # We can add this table to the joins
            @join_tables << join_table_name

          end
        end
      end
    end

    # Make the list of tables to be joined valid (in case anything slipped through) and unique
    @join_tables = (@join_tables - NonJoinTableNames).uniq

    if @join_tables.first == :users
      # Just get from the non masters tables without a join
      @base_query = User.all
      @current_scope = User.all
      # @current_scope = @base_query
    elsif %i[all not_all].include? condition_type
      # Inner join, since our conditions require the existence of records in the joined tables
      @base_query = @current_scope.joins(@join_tables)
    else
      # Left join, since our conditions do not absolutely require the existence of records in the joined tables
      @base_query = @current_scope.includes(@join_tables)
    end
  end

  # Create a dynamic value if the condition's value matches certain strings
  def dynamic_value(val, type = nil)
    FieldDefaults.calculate_default(current_instance, val, type, allow_nil: true)
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
      st = is_selection_type c_type
      next unless st

      ca = ConditionalActions.new({ c_type => t_conds }, current_instance, current_scope: @condition_scope,
                                                                           return_failures: return_failures)
      res_a = ca.calc_action_if

      if return_first_false
        res &&= res_a
        return nil unless res
      else
        res ||= res_a
      end

      @this_val ||= ca.this_val
    end

    res
  end

  # Check if this is a key we won't join on, or if it is a selection type (such as and:, :not_all...)
  # @param key [Symbol]
  # @return [True | False]
  def non_join_table_name?(key)
    (key.in?(NonJoinTableNames) || is_selection_type(key))
  end

  # Check if this is a key that represents part of a non query condition, or if it is a selection type (such as and:, :not_all...)
  # @param key [Symbol]
  # @return [True | False]
  def non_query_nested_key_name?(key)
    (key.in?(NonQueryNestedKeyNames) || is_selection_type(key))
  end

  # Check if the supplied key is a selection type, starting :all, :not_all, :any, :not_any
  # Allow the same selection type to be used multiple times, such as:
  # not_any:
  # not_any_2:
  # not_any_3:
  # @param key [Symbol]
  # @return [True | False]
  def is_selection_type(key)
    return key if key.in?(SelectionTypes)

    SelectionTypes.select { |st| key.to_s.start_with? st.to_s }.first
  end

  # Evaluate if this definition represents a non query condition, to be evaluated without
  # directly joining on the master table
  # @param table_name [Symbol] table key from definition
  # @param field_name [Symbol] field name key from definition
  # @param val [Hash | Object] the condition definition
  def is_non_query_condition(table_name, field_name, val)
    # Simple table keys handled by non query conditions
    non_query_condition = table_name.in?(NonQueryTableNames) || is_selection_type(table_name)

    # Requesting a return constant in any circumstance requires a non query condition
    non_query_condition = true if field_name == :return_constant

    # If there is a nested condition, the key may represent a non query table name
    val_item_key = val.is_a?(Hash) && val.first.is_a?(Hash) && val.first.first
    non_query_condition ||= non_query_nested_key_name?(val_item_key) if val_item_key

    non_query_condition
  end

  # Calculate a validation based on a :validate key
  # @param condition [Hash] defined validation condition
  # @param value [Object] actual value of the expected result
  # @return [Type] description_of_returned_object
  def calc_complex_validation(condition, value)
    res = true
    condition.each do |k, opts|
      v = new_validator k, value, options: { k => opts }
      test_res = v.value_is_valid? value, current_instance
      res &&= test_res
    end

    res
  end

  def new_validator(k, value, options: {})
    validator_class(k).new options.merge(attributes: { _attr: value })
  end

  def validator_class(k)
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
  def expected_value_requests_return?(type, condition)
    ret_type = "return_#{type}"
    condition == ret_type || condition.is_a?(Array) && condition.include?(ret_type)
  end

  # Logging of results to aid debugging
  def log_results(orig_cond_type, condition_type, loop_res, cond_res, orig_loop_res)
    return if Rails.env.production?

    begin
      Rails.logger.debug "**#{orig_cond_type}*******************************************************************************************************"
      Rails.logger.debug "this instance: #{@current_instance.id}"
      Rails.logger.debug "condition_type: #{condition_type} - loop_res: #{loop_res} - cond_res: #{cond_res} - orig_loop_res: #{orig_loop_res}"
      Rails.logger.debug @condition_config
      Rails.logger.debug @non_query_conditions
      Rails.logger.debug @base_query.to_sql if @base_query
      Rails.logger.debug @condition_scope.to_sql if @condition_scope
      Rails.logger.debug '*********************************************************************************************************'
    rescue StandardError => e
      Rails.logger.warn "condition_type: #{condition_type} - loop_res: #{loop_res} - cond_res: #{cond_res} - orig_loop_res: #{orig_loop_res}"
      Rails.logger.warn @condition_config
      Rails.logger.warn @join_tables
      Rails.logger.warn JSON.pretty_generate(@action_conf)
      Rails.logger.warn "Failure in calc_actions: #{e}\n#{e.backtrace.join("\n")}"
      raise e
    end
  end
end
