# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the redcap_request save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class RedcapRequest < Base
      trigger_name :redcap_request
      pattern :named_entry
      allowed_keys %i[
        study project_name local_data method post_data success_if
        force_not_editable_save data_field data_field_format on_complete on_failure if
      ]
      standard_hook_key_types
      key_type :string_or_hash, :study, :project_name, :local_data, :method, :data_field, :data_field_format
      key_type :scalar_or_array_or_hash, :post_data
      key_type :hash, :success_if
      key_type :boolean, :force_not_editable_save
    end
  end
end
