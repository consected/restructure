# frozen_string_literal: true

module CalcActions
  module Common
    UnsetThisVal = Object.new.freeze

    SelectionTypes = %i[all any not_all not_any].freeze

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

    BoolTypeString = '__!BOOL__'
    UnaryConditions = ['IS NOT NULL', 'IS NULL'].freeze
    BinaryConditions = ['=', '<', '>', '<>', '<=', '>=', 'LIKE', 'ILIKE', '~*', '~', 'in?', 'include?'].freeze
    ValidExtraConditions = (BinaryConditions + UnaryConditions).freeze

    attr_accessor :return_this, :top_level_error, :top_level_error_above, :skip_merge

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
      val ||= from_instance.instance_variable_get("@#{attr_name}")

      if val.blank? && attr_name.to_s.start_with?('previous_value_of_') && from_instance.respond_to?(:previous_changes)
        real_attr_name = attr_name.to_s.sub(/^previous_value_of_/, '')
        val = from_instance.previous_changes[real_attr_name]&.first
      end

      attr_type = from_instance.type_for_attribute(attr_name).type
      val = nil if val.blank? && attr_type != :string
      val = false if val.nil? && attr_type == :boolean
      val
    end

    # Check if the supplied key is a selection type, starting :all, :not_all, :any, :not_any
    # Allow the same selection type to be used multiple times, such as:
    # not_any:
    # not_any_2:
    # not_any_3:
    # @param key [Symbol]
    # @return [True | False]
    def selection_type?(key)
      return key if key.in?(SelectionTypes)

      SelectionTypes.select { |st| key.to_s.start_with? st.to_s }.first
    end

    # Create a dynamic value if the condition's value matches certain strings
    def dynamic_value(val, type = nil)
      FieldDefaults.calculate_default(current_instance, val, type, allow_nil: true)
    end

    # Does the condition contain a return_value or return_result string
    # @param type [Symbol | String] :value or :result indicating whether the request wants
    #   a result value or an instance returned
    # @param condition [String | Array] the condition to test
    # @return [True | False]
    def expected_value_requests_return?(type, condition)
      ret_type = "return_#{type}"
      (condition == ret_type) || (condition.is_a?(Array) && condition.include?(ret_type))
    end

    #
    # For validation, we need to know what failed. Merge the failures from multiple different tests
    # @param results [Hash] The results to be merged follow this format:
    #   {
    #     @condition_type => {
    #       table => {
    #         field_name => expected_val
    #       }
    #     }
    #   }
    #
    # If invalid_error_message is set at some level, return the most specific one where the validation failed
    # If a validate: definition failed, get the message from that instead.
    def merge_failures(results)
      return unless return_failures && !@skip_merge

      # Make sure we don't overwrite the actual results passed in, since these
      # can be the actual @condition_config or other objects that shouldn't be changed
      res_changes = {}
      tl_changes = {}
      res_key = results.first.first
      res_conds = results.first.last.dup
      return if res_conds.empty?

      cond_changes = res_conds.dup

      res_conds.each do |t, res|
        next unless res.is_a?(Hash) && res.present?

        field = res.first.first
        conf = @condition_config.first.last
        val_msg = conf[field] if conf.is_a?(Hash)
        msg = val_msg[:invalid_error_message] if val_msg.is_a?(Hash)
        msg ||= condition_error_message
        if @top_level_error
          res = tl_changes[t] = { top_level_error: { invalid_error_message: @top_level_error } }
          cond_changes.delete(t)
          next
        elsif msg.present?
          msg = { invalid_error_message: msg }
          res = res_changes[t] = { field => msg }
          cond_changes.delete(t)
          next
        end

        next unless res.is_a?(Hash) && res.first&.last.is_a?(Hash) && res.first&.last&.first&.first == :validate

        res_changes[t] =
          { field => new_validator(res_changes[:validate].first.first, nil, options: {}).message }
        next
      end

      return if @top_level_error_above && @top_level_error_above == @top_level_error

      return_failures.deep_merge!(res_key => tl_changes) if tl_changes.present?
      return if @top_level_error_above

      return_failures.deep_merge!(res_key => cond_changes) if cond_changes.present?
      return_failures.deep_merge!(res_key => res_conds.merge(res_changes)) unless res_changes.empty?
    end

    #
    # Setup the error message for the current condition loop if there is an :invalid_error_message key
    def condition_error_message
      return @condition_error_message if @got_condition_error_message

      @got_condition_error_message = true
      @top_level_error ||= false
      return unless @condition_config.respond_to?(:key?)

      @condition_error_message = if @condition_config.first.last.is_a?(Hash)
                                   @condition_config.first.last[:invalid_error_message]
                                 else
                                   @top_level_error = true
                                   @condition_config.first.last
                                 end
    end

    #
    # Allows this_val to be passed so it can be changed in nested and non-query conditions.
    def this_val=(value)
      return_this[:value] = value
    end

    # Gets the successfully evaluated return value.
    # We gracefully return nil (rather than raising an exception) if the value is unset.
    # This is critical because normal ConditionalActions rules that evaluate to false 
    # (e.g. no matching records found) naturally bypass the return bindings and never set 
    # a value. Callers like get_this_val rely on this returning nil to propagate a 
    # non-match logic up the stack. Strict operations (like lookup sub-queries) check 
    # this_val_set? separately to assert when a value was strictly required.
    def this_val
      return nil unless this_val_set?

      return_this[:value]
    end

    def this_val_set?
      !return_this[:value].equal?(UnsetThisVal)
    end

    def this_val_mode=(value)
      return_this[:mode] = value
    end

    def this_val_mode
      return_this[:mode]
    end

    #
    # Set up the validator, typically based on the value from a validate: key
    def new_validator(val_name, value, options: {})
      validator_class(val_name).new options.merge(attributes: { _attr: value })
    end

    #
    # Handle consistent naming for validator classes
    def validator_class(val_name)
      Validates.const_get("#{val_name.to_s.classify}Validator")
    end
  end
end
