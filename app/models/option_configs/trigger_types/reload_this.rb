# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the reload_this save trigger.
    # Direct-config pattern: only accepts universal keys.
    class ReloadThis < Base
      trigger_name :reload_this
      pattern :direct_config
      allowed_keys %i[if on_complete on_failure]
      standard_hook_key_types
    end
  end
end
