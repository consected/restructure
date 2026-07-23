# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the pull_external_data save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class PullExternalData < Base
      trigger_name :pull_external_data
      pattern :named_entry
      allowed_keys %i[
        if force_not_editable_save force_not_valid local_data data_field data_field_format
        response_code_field method from to post_data send_data form success_if on_complete on_failure
      ]
      standard_hook_key_types
      key_type :boolean, :force_not_editable_save, :force_not_valid
      key_type :string, :local_data, :data_field, :data_field_format, :response_code_field, :method
      # from and to are always Hashes with sub-keys (url:, format:, etc.);
      # a String value would raise TypeError at runtime when sub_config[:url] is called.
      key_type :hash, :from, :to, :success_if, :form
      key_type :scalar_or_array_or_hash, :post_data, :send_data
    end
  end
end
