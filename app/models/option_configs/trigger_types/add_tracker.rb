# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the add_tracker save trigger.
    # Named-entry pattern: config is { protocol_name: { actual_keys... } }.
    class AddTracker < Base
      trigger_name :add_tracker
      pattern :named_entry
      allowed_keys %i[if with on_complete on_failure]
      standard_hook_key_types
      key_type :hash, :with
    end
  end
end
