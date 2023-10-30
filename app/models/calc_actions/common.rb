# frozen_string_literal: true

module CalcActions
  module Common
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
    BinaryConditions = ['=', '<', '>', '<>', '<=', '>=', 'LIKE', 'ILIKE', '~*', '~'].freeze
    ValidExtraConditions = (BinaryConditions + UnaryConditions).freeze

    attr_accessor :return_this

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
      condition == ret_type || condition.is_a?(Array) && condition.include?(ret_type)
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

      results.first.last.each do |t, res|
        field = res.first.first
        conf = @condition_config.first.last
        val_msg = conf[field] if conf.is_a?(Hash)
        msg = val_msg[:invalid_error_message] if val_msg.is_a?(Hash)
        msg ||= condition_error_message
        if msg
          res = results.first.last[t] = { field => msg }
          next
        end

        next unless res.is_a?(Hash) && res.first&.last.is_a?(Hash) && res.first&.last&.first&.first == :validate

        results.first.last[t] =
          { field => new_validator(res.first.last[:validate].first.first, nil, options: {}).message }
        next
      end
      return_failures.deep_merge!(results)
    end

    #
    # Setup the error message for the current condition loop if there is an :invalid_error_message key
    def condition_error_message
      return @condition_error_message if @got_condition_error_message

      @got_condition_error_message = true
      @condition_error_message = @condition_config.respond_to?(:key?) &&
                                 @condition_config.first.last.delete(:invalid_error_message)
    end

    #
    # Allows this_val to be passed so it can be changed in nested and non-query conditions
    def this_val=(value)
      return_this[:value] = value
    end

    def this_val
      return_this[:value]
    end
  end
end
