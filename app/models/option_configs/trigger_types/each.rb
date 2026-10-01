# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the composable each save trigger.
    class Each < Base
      trigger_name :each
      pattern :delegate
      allowed_keys %i[value iterator_name if do on_complete on_failure]
      standard_hook_key_types
      key_type :scalar_or_array_or_hash, :value
      key_type :string, :iterator_name
      key_type :hash_or_array, :do
    end
  end
end
