# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the create_reference save trigger.
    # Named-entry pattern: config is { model_name: { actual_keys... } }.
    class CreateReference < Base
      trigger_name :create_reference
      pattern :named_entry
      allowed_keys %i[if in force_create force_not_valid with_result with on_complete on_failure to_existing_record]
      key_type :boolean, :force_create, :force_not_valid
    end
  end
end
