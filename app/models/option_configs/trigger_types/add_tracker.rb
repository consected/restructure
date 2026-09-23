# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the add_tracker save trigger.
    # Named-entry pattern: config is { protocol_name: { actual_keys... } }.
    class AddTracker < Base
      trigger_name :add_tracker
      pattern :named_entry
      # SaveTriggers::AddTracker#perform always expects `protocol_name: { with: ... }` - an
      # unwrapped config is misread as if `with` were the protocol name (see issue #1444).
      no_direct_form
      allowed_keys %i[if with on_complete on_failure]
      standard_hook_key_types
      key_type :hash, :with
    end
  end
end
