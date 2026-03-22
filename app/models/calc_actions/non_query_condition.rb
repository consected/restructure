# frozen_string_literal: true

module CalcActions
  # Handles non-query conditions for CalcActions::Calculate
  class NonQueryCondition
    include Common

    NonQueryTableNames = %i[this user parent referring_record top_referring_record embedded_item role_name
                            reference].freeze

    NonQueryNestedKeyNames = %i[this referring_record top_referring_record embedded_item this_references parent_references
                                parent_or_this_references reference validate].freeze

    SimpleConditions = ['==', '=', '<', '>', '<>', '!=', '<=', '>=', '~*', '~', 'in?', 'include?'].freeze

    ValidCalculateFunctions = %i[sum min max count_not_null mean].freeze

    attr_accessor :table, :field_name, :condition_def, :current_instance, :return_failures,
                  :conditions, :condition_config

    #
    # @return [true | false]
    def initialize(current_instance: nil, table: nil, field_name: nil, condition_def: nil,
                   return_failures: nil, return_this: nil, condition_config: nil,
                   top_level_error: nil, top_level_error_above: nil)
      self.current_instance = current_instance
      self.table = table
      self.field_name = field_name
      self.condition_def = condition_def
      self.return_failures = return_failures
      self.return_this = return_this
      self.condition_config = condition_config
      self.top_level_error = top_level_error
      self.top_level_error_above = top_level_error_above

      self.conditions = {}
    end

    # Evaluate if this definition represents a non query condition, to be evaluated without
    # directly joining on the master table
    # @param [Hash | Object] definition - the condition definition
    # @return [true | false]
    def non_query_condition?(field_name, definition)
      # Simple table keys handled by non query conditions
      non_query_condition = table.in?(NonQueryTableNames) || selection_type?(table)

      # Requesting a return constant in any circumstance requires a non query condition
      non_query_condition = true if field_name == :return_constant

      non_query_condition = true if field_name == :calculate

      # If there is a nested condition, the key may represent a non query table name
      val_item_key = definition.is_a?(Hash) && definition.first.is_a?(Hash) && definition.first.first
      non_query_condition ||= non_query_nested_key_name?(val_item_key) if val_item_key

      !!non_query_condition
    end

    #
    # Set a non-query condition for this table and field
    def add(table_name, field_name, val)
      return unless non_query_condition?(field_name, val)

      # We have decided this is a non query condition, and will not be joined on the master
      # Add this so they can be evaluated at runtime.

      conditions[table_name] ||= {}
      conditions[table_name][field_name] = val

      true
    end

    def condition_type_all
      res_q = true
      conditions.each do |table, fields|
        fields.each do |field_name, condition_def|
          res = calc_non_query_condition(table, field_name, condition_def)
          merge_failures(all: { table => { field_name => condition_def } }) unless res
          res_q &&= res
        end
      end
      res_q
    end

    def condition_type_not_all
      res_q = true
      conditions.each do |table, fields|
        fields.each do |field_name, expected_val|
          res_q &&= calc_non_query_condition(table, field_name, expected_val)
        end
      end
      res_q
    end

    def condition_type_any
      res_q = false
      conditions.each do |table, fields|
        fields.each do |field_name, expected_val|
          res_q ||= calc_non_query_condition(table, field_name, expected_val)
          break if res_q
        end
      end
      res_q
    end

    def condition_type_not_any
      res = true
      conditions.each do |table, fields|
        fields.each do |field_name, expected_val|
          res_q = !calc_non_query_condition(table, field_name, expected_val)
          merge_failures(not_any: { table => { field_name => expected_val } }) unless res_q
          res &&= res_q
        end
      end
      res
    end

    def calc_non_query_condition(table, field_name, condition_def)
      self.table = table
      self.field_name = field_name
      self.condition_def = condition_def
      calc_result
    end

    #
    # Calculate non query condition results and nested conditions, comparing against expected values
    # Multiple expected values may be specified, typically where a nested condition is defined.
    # self.this_val attribute is set to return the last value from a definition. Used for simple lookups
    # @return [true | false]
    def calc_result
      @skip_merge = false

      res = true
      # Allow a list of possible conditions to be used
      self.condition_def = [condition_def] unless condition_def.is_a?(Array) && condition_def.first.is_a?(Hash)

      condition_def.each do |expected_val|
        if field_name == :return_constant
          # The literal value specified will be returned
          # some_table:
          #   return_constant: value to return
          self.this_val = expected_val
          return true
        end

        if table == :user && field_name == :role_name
          #### If we have a user as the table key and we are requesting the role_name
          # to match the expected value
          res &&= non_query_user_role_name(expected_val)
        elsif table.in?(NonQueryTableNames)
          #### If we have a non-query table specified

          if field_name == :exists
            # Simply get a true result if instance found and {exists: true} or
            # instance not found and {exists: false}
            res = self.this_val = (!!expected_val == !!in_instance)
            @skip_merge = true

          elsif !in_instance
            # We failed to find the instance we need to continue.
            raise FphsException, "Instance not found for #{table}"

          elsif field_name == :calculate
            res = eval_calculation(calculate: expected_val)
            self.this_val = res
          elsif expected_val.is_a?(Hash) && !(
            expected_val.key?(:element) || expected_val.key?(:calculate) ||
            expected_val.key?(:condition) && table == :this
          )
            res &&= non_query_expected_val_hash(expected_val)
          else
            res &&= non_query_expected_val_not_a_hash(expected_val)
          end
        end
        #### Any other table keys are just ignored
      end

      # Return the result
      res
    end

    #
    # An expected value hash may mean several things, including
    # field (not just equals) conditions, validations and nested conditions
    #
    # If this is a field condition (something other than equals), set it up to be calculated
    # Generate a query that references the in_instance object through its association,
    # specifying the id as an expected value, plus the condition to be calculated within the query
    # This forces us to run this as a nested condition.
    def non_query_expected_val_hash(expected_val)
      if expected_val[:condition]
        assoc_name = ModelReference.record_type_to_assoc_sym(in_instance)
        expected_val = { assoc_name => { field_name => expected_val, id: in_instance.id } }
        self.field_name = :all
      end

      if selection_type?(field_name)
        #### Handle a Nested Condition
        # If we have the field name key being all, any, etc, then run the nested conditions
        # with the current condition scope
        # We set top_level_error_above since the all/any/not... indicates we are at a new level
        ca = ConditionalActions.new({ field_name => expected_val },
                                    in_instance,
                                    current_scope: @condition_scope,
                                    return_failures:,
                                    return_this:,
                                    top_level_error:,
                                    top_level_error_above: top_level_error)
        res = ca.calc_action_if

      elsif expected_val.keys.first == :validate
        #### Handle validate
        # take the validate definition and calculate the result
        res = calc_complex_validation expected_val[:validate], in_instance.attributes[field_name.to_s]

      elsif !selection_type?(field_name) &&
            expected_val.values.find { |f| f.is_a?(Hash) && f.values.include?('return_value') }

        ca = ConditionalActions.new({ all: expected_val },
                                    in_instance,
                                    current_scope: @condition_scope,
                                    return_failures:,
                                    return_this:,
                                    top_level_error:,
                                    top_level_error_above:)
        returned_value = ca.get_this_val
        @skip_merge = true
        res = in_instance.attributes[field_name.to_s] == returned_value
      else
        #### Handle a previously unhandled nested condition
        ca = ConditionalActions.new({ all: { field_name => expected_val } },
                                    in_instance,
                                    current_scope: @condition_scope,
                                    return_failures:,
                                    return_this:,
                                    top_level_error:,
                                    top_level_error_above:)
        res = ca.calc_action_if
        @skip_merge = true

        #### Something was wrong in the definition
        # raise FphsException, <<~ERROR_MSG
        #   calc_non_query_condition field is not a selection type or :validate hash. Ensure you have an all, any, not_any, not_all before all nested expressions.

        #   #{@condition_config.to_yaml}
        # ERROR_MSG
      end
      res
    end

    #
    # The expected value was not a hash.
    # Simply handle the comparison and return the result
    # Also set a value or result instance if requested
    def non_query_expected_val_not_a_hash(expected_val)
      # Get the value

      expected_val = eval_calculation(expected_val)

      loc_this_val = attribute_from_instance(in_instance, field_name)

      res = if expected_val.is_a?(Hash) && expected_val[:element] && loc_this_val.is_a?(Hash)
              element = expected_val[:element]
              test_value = traverse_element(loc_this_val, element)
              eval_simple_condition(test_value, expected_val)
            else
              # Simply compare the expected value against the one we found
              eval_simple_condition(loc_this_val, expected_val)
            end

      # Handle return value or result
      if expected_value_requests_return? :value, expected_val
        self.this_val = loc_this_val
      elsif expected_value_requests_return? :result, expected_val
        self.this_val = in_instance
      end
      res
    end

    #
    # Check if current user role names in one of the specified { user: { role_name: <string | array> }}
    def non_query_user_role_name(expected_val)
      user = @current_instance.current_user
      raise FphsException, 'Current user not set when specifying evaluation if user.role_name' unless user

      expected_val = [expected_val] unless expected_val.is_a? Array

      role_names = user.role_names
      self.this_val = role_names if expected_value_requests_return? :value, expected_val
      role_res = false
      expected_val.each do |e|
        role_res ||= role_names.include? e
      end
      role_res
    end

    #
    # Pick the instance we are referring to by *table* or nil if none match
    # Result is memoized
    # @return [Object | nil]
    def in_instance
      @in_instances ||= {}
      return @in_instances[table] if @in_instances.key?(table)

      @in_instances[table] = case table
                             when :this
                               current_instance
                             when :user
                               @current_instance.current_user
                             when :parent
                               current_instance.parent_item
                             when :referring_record
                               current_instance.referring_record
                             when :top_referring_record
                               current_instance.top_referring_record
                             when :reference
                               current_instance.reference
                             when :embedded_item
                               current_instance.embedded_item(embed_action_type: :viewing)
                             end
    end

    # Evaluated simple conditions
    def eval_simple_condition(test_val, expected_val)
      if expected_val.is_a? Array
        # Since we have expected value as an array, simply see if it includes the value we found
        expected_val.include?(test_val)
      elsif expected_val.is_a?(Hash) || expected_val.is_a?(Array)
        condition = expected_val[:condition] || '=='
        exp_val = dynamic_value(expected_val[:value])
        res = if condition.in?(SimpleConditions)
                test_simple_conditions condition, test_val, exp_val
              elsif condition.in?(UnaryConditions)
                test_unary_conditions condition, test_val, exp_val
              elsif condition.in?(ValidExtraConditionsArrays)
                test_array_conditions condition, test_val, exp_val
              else
                raise FphsException, "calc_action this condition is not recognized: #{condition}"
              end
        # Optionally negate the result
        res = !res if expected_val[:not]
        res
      else
        test_val == dynamic_value(expected_val)
      end
    end

    def eval_calculation(expected_val)
      calc = expected_val[:calculate] if expected_val.is_a? Hash
      return expected_val unless calc

      fn = calc.first.first
      valid_fn = ValidCalculateFunctions.find { |f| f == fn }
      raise FphsException, "Invalid calculate function: #{fn}" unless valid_fn

      vals = calc.first.last
      vals[:attributes].map { |a| in_instance.attributes[a] }.send(valid_fn)
    end

    def test_simple_conditions(condition, test_val, exp_val)
      case condition
      when '=', '=='
        if exp_val.is_a?(Array) && !test_val.is_a?(Array)
          test_val.in?(exp_val)
        else
          test_val == exp_val
        end
      when '<>'
        test_val != exp_val
      when '~'
        test_val&.match(Regexp.new(exp_val))
      when '~*'
        test_val&.match(Regexp.new(exp_val, 'i'))
      else
        test_val&.send(condition, exp_val)
      end
    end

    def test_unary_conditions(condition, test_val, _exp_val)
      case condition
      when 'IS NULL'
        test_val.nil?
      when 'IS NOT NULL'
        !test_val.nil?
      end
    end

    def test_array_conditions(condition, test_val, exp_val)
      case condition
      when '= ANY' # The value of this field (must be scalar) matches any value from the retrieved array field
        exp_val&.in?(test_val || [])
      when '= ANY REV' # Reverse the operator order
        test_val&.in?(exp_val || [])
      when '<> ANY' # The value of this field (must be scalar) must not match any value from the retrieved array field
        !exp_val&.in?(test_val || [])
      when '<> ANY REV' # Reverse the operator order
        !test_val&.in?(exp_val || [])
      when '= ARRAY_LENGTH' # value of this field (must be integer) equals the length of the retrieved array field
        test_val&.length == exp_val.to_i
      when '<> ARRAY_LENGTH' # value of this field (must be integer) must not equal length of the retrieved array field
        test_val&.length != exp_val.to_i
      when '= LENGTH' # value of this field (must be integer) equals the length of the string (varchar or text) field
        test_val&.length == exp_val.to_i
      when '<> LENGTH' # value of this field (must be integer) must not equal length of the string (varchar/text) field
        test_val&.length != exp_val.to_i
      when '&&' # There is an overlap, so any value of this field (an array) must be in the retrieved array field
        ((test_val || []) & (exp_val || []))&.present?
      when '@>' # This array field contains all of the elements of the retrieved array field
        raise FphsException, '@> not implemented for this'
      when '<@' # This array field's elements are all found in the retrieved array field
        raise FphsException, '<@ not implemented for this'
      end
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

    #
    # Traverse the value according to the *path*.
    # @param [Hash|Array] value
    # @param [String] element
    # @return [String] <description>
    def traverse_element(value, path)
      return unless value

      value_here = value
      el_parts = path.split('.')
      el_parts.each do |seg|
        if value_here.is_a?(Hash)
          value_here = value_here.stringify_keys[seg]
        elsif value_here.is_a?(Array)
          seg = case seg
                when 'first'
                  0
                when 'last'
                  -1
                else
                  seg
                end
          seg = seg.to_i
          value_here = value_here[seg]
        end
      end
      value_here
    end

    # Check if this is a key that represents part of a non query condition, or if it is
    # a selection type (such as and:, :not_all...)
    # @param key [Symbol]
    # @return [True | False]
    def non_query_nested_key_name?(key)
      key.in?(NonQueryNestedKeyNames) || selection_type?(key)
    end
  end
end
