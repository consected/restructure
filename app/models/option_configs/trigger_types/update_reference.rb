# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the update_reference save trigger.
    # Named-entry pattern: config is { model_name: { actual_keys... } }.
    class UpdateReference < Base
      trigger_name :update_reference
      pattern :named_entry
      allowed_keys %i[if first force_not_editable_save force_not_valid with_result with on_complete on_failure]
      standard_hook_key_types
      key_type :scalar_or_array_or_hash, :first
      key_type :boolean, :force_not_editable_save, :force_not_valid
      key_type :hash_or_array, :with_result
      key_type :hash, :with
    end
  end
end
