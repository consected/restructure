# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the run_batch_trigger save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class RunBatchTrigger < Base
      trigger_name :run_batch_trigger
      pattern :named_entry
      allowed_keys %i[if resource_name mode limit on_complete on_failure]
      standard_hook_key_types
      key_type :string, :resource_name, :mode
      key_type :integer, :limit
    end
  end
end
