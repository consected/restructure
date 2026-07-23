# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the set_variables save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class SetVariables < Base
      trigger_name :set_variables
      pattern :named_entry
      allowed_keys %i[if name value on_complete on_failure]
      standard_hook_key_types
      key_type :string, :name
      key_type :scalar_or_array_or_hash, :value
    end
  end
end
