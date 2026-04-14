# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the set_item_flags save trigger.
    # Direct-config pattern: keys are directly on the trigger config hash.
    class SetItemFlags < Base
      trigger_name :set_item_flags
      pattern :direct_config
      allowed_keys %i[first if force_not_editable_save flags add_flags remove_flags on_complete on_failure]
      key_type :boolean, :force_not_editable_save
    end
  end
end
