# frozen_string_literal: true

#
# Save trigger to explicitly set values in save_trigger_results,
# making them available to subsequent triggers via substitutions
# like {{save_trigger_results.element_name}} or conditional actions.
#
# Values can be literals, substitution strings, or object hashes.
# Dot-notation in element names (e.g. 'hash_variable.key1') sets
# nested keys within save_trigger_results.
#
# Example configuration:
#   save_trigger:
#     on_create:
#       - set_save_trigger_results:
#           element: simple_variable
#           value: 123
#       - set_save_trigger_results:
#           element: hash_variable
#           value:
#             object:
#               id: '{{study_id}}'
#       - set_save_trigger_results:
#           if:
#             all:
#               this:
#                 select_call_direction: from player
#           element: conditional_variable
#           value: 'was from player'
#
class SaveTriggers::SetSaveTriggerResults < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super

    @model_defs = config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    results = []
    @model_defs.each do |model_def|
      config = extract_config(model_def)

      # Evaluate conditional if
      next unless if_evaluates(config[:if])

      element = config[:element]
      raise FphsException, 'set_save_trigger_results requires element to be specified' if element.blank?

      value = config[:value]

      # Calculate the value using FieldDefaults, supporting substitutions,
      # conditional actions, and object values.
      # For object: hashes, also perform substitutions on the inner values.
      calculated_value = FieldDefaults.calculate_default(@item, value, allow_nil: true)
      calculated_value = substitute_object_values(calculated_value) if calculated_value.is_a?(Hash)

      # Set the value in save_trigger_results, supporting dot-notation for nested keys
      set_nested_value(element.to_s, calculated_value)

      results << { element: element.to_s, value: calculated_value }
    end

    results
  end

  private

  #
  # Set a value in save_trigger_results, supporting dot-notation
  # for nested keys (e.g. 'hash_variable.key1' sets
  # save_trigger_results['hash_variable']['key1'])
  # @param [String] element - the element path (may contain dots)
  # @param [Object] value - the value to set
  def set_nested_value(element, value)
    return unless @item.respond_to?(:save_trigger_results) && @item.save_trigger_results

    parts = element.split('.')
    if parts.length == 1
      @item.save_trigger_results[element] = value
    else
      # Navigate to the nested location, creating intermediate hashes as needed
      target = @item.save_trigger_results
      parts[0..-2].each do |key|
        target[key] ||= {}
        target = target[key]
      end
      target[parts.last] = value
    end
  end

  #
  # Recursively perform substitutions on all string values within a hash.
  # This enables the object: key pattern to include {{substitutions}}.
  # @param [Hash] hash_value - the hash whose values should be substituted
  # @return [Hash] the hash with substituted string values
  def substitute_object_values(hash_value)
    hash_value.deep_transform_values do |v|
      FieldDefaults.calculate_default(@item, v, allow_nil: true)
    end
  end

  #
  # Extract configuration from the model_def, handling both simple and named formats
  # @param [Hash] model_def - either { element: 'x', value: 'y' } or { name: { element: 'x', value: 'y' } }
  # @return [Hash] - the configuration hash
  def extract_config(model_def)
    return model_def unless model_def.is_a?(Hash)

    # Simple format: config is directly provided with element key
    return model_def if model_def.key?(:element)

    # Named format: first value should be a hash config
    first_val = model_def.values.first
    return first_val if first_val.is_a?(Hash)

    # Default to returning the original
    model_def
  end
end
