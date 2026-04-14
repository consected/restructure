# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the update_this save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class UpdateThis < Base
      trigger_name :update_this
      pattern :named_entry
      allowed_keys %i[if force_not_editable_save force_not_valid with_result with on_complete on_failure]
      standard_hook_key_types
      key_type :boolean, :force_not_editable_save, :force_not_valid
      key_type :hash_or_array, :with_result
      key_type :hash, :with
    end
  end
end
