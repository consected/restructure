# frozen_string_literal: true

#
# Save trigger to set variables, making them available to subsequent
# triggers and substitutions via {{variables.varname}} tags.
#
# This brings the set_variables dynamic definition configuration
# (normally used in extra option types) into the save trigger context,
# following the model of set_save_trigger_results.
#
# Values can be literals, substitution strings, or object hashes.
# Dot-notation in names (e.g. 'hash_var.key1') sets nested keys.
#
# Example configuration:
#   save_trigger:
#     on_create:
#       - set_variables:
#           name: simple_var
#           value: 123
#       - set_variables:
#           name: hash_var
#           value:
#             object:
#               id: '{{study_id}}'
#       - set_variables:
#           if:
#             all:
#               this:
#                 select_call_direction: from player
#           name: conditional_var
#           value: 'was from player'
#
class SaveTriggers::SetVariables < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super

    @model_defs = config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    results = []
    @model_defs.each do |model_def|
      config = model_def
      config = config.symbolize_keys if config.is_a?(Hash)
      with_entry_lifecycle(config) do
        # Evaluate conditional if
        next unless if_evaluates(config[:if])

        name = config[:name]
        raise FphsException, 'set_variables requires name to be specified' if name.blank?

        # Substitute tags in the name field (e.g. for dynamic iterator_index)
        name = FieldDefaults.calculate_default(@item, name.to_s, ignore_missing: true)

        value = config[:value]

        # Calculate the value using FieldDefaults, supporting substitutions,
        # conditional actions, and object values.
        calculated_value = FieldDefaults.calculate_default(@item, value, allow_nil: true)

        # Set the value in trigger_variables, supporting dot-notation for nested keys
        set_nested_value(name.to_s, calculated_value)

        results << { name: name.to_s, value: calculated_value }
      end
    end

    results
  end

  private

  #
  # Set a value in trigger_variables, supporting dot-notation
  # for nested keys (e.g. 'hash_var.key1' sets
  # trigger_variables[:hash_var][:key1])
  # @param [String] name - the variable name (may contain dots)
  # @param [Object] value - the value to set
  def set_nested_value(name, value)
    return unless @item.respond_to?(:trigger_variables) && @item.trigger_variables

    parts = name.split('.')
    if parts.length == 1
      @item.trigger_variables[name.to_sym] = value
    else
      # Navigate to the nested location, creating intermediate hashes as needed
      target = @item.trigger_variables
      parts[0..-2].each do |key|
        target[key.to_sym] ||= {}
        target = target[key.to_sym]
      end
      target[parts.last.to_sym] = value
    end
  end
end
