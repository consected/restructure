# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the set_save_trigger_results save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class SetSaveTriggerResults < Base
      trigger_name :set_save_trigger_results
      pattern :named_entry
      allowed_keys %i[if element value on_complete on_failure]
      key_type :string, :element
    end
  end
end
