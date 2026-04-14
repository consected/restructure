# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the create_master save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class CreateMaster < Base
      trigger_name :create_master
      pattern :named_entry
      allowed_keys %i[if force_create move_this with on_complete on_failure]
      key_type :boolean, :force_create, :move_this
    end
  end
end
