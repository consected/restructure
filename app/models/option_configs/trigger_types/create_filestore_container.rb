# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the create_filestore_container save trigger.
    # Direct-config pattern: keys are directly on the trigger config hash.
    class CreateFilestoreContainer < Base
      trigger_name :create_filestore_container
      pattern :direct_config
      allowed_keys %i[name label create_with_role if on_complete on_failure]
      standard_hook_key_types
      key_type :string_or_hash, :name, :label, :create_with_role
    end
  end
end
