# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the create_master save trigger.
    # Direct-config pattern: config is a direct Hash of keys.
    # Runtime: SaveTriggers::CreateMaster accesses config keys directly.
    class CreateMaster < Base
      trigger_name :create_master
      pattern :direct_config
      allowed_keys %i[if force_create move_this with on_complete on_failure]
      standard_hook_key_types
      key_type :boolean, :force_create, :move_this
      key_type :hash, :with
    end
  end
end
