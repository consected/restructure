# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the pull_external_data save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class PullExternalData < Base
      trigger_name :pull_external_data
      pattern :named_entry
      allowed_keys %i[
        if force_not_editable_save local_data data_field data_field_format
        response_code_field method from to post_data success_if on_complete on_failure
      ]
      standard_hook_key_types
      key_type :boolean, :force_not_editable_save
      key_type :string_or_hash, :local_data, :data_field, :data_field_format, :response_code_field, :method,
               :from, :to
      key_type :hash, :success_if
      key_type :scalar_or_array_or_hash, :post_data
    end
  end
end
