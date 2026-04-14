# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the full_text_search save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class FullTextSearch < Base
      trigger_name :full_text_search
      pattern :named_entry
      allowed_keys %i[source_fields target_column extra_content ts_config if on_complete on_failure]
      standard_hook_key_types
      key_type :string_or_array, :source_fields
      key_type :string, :target_column, :ts_config
      key_type :scalar_or_array_or_hash, :extra_content
    end
  end
end
