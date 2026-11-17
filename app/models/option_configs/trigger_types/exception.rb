# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the exception save trigger.
    # Direct-config pattern: config is a Hash of exception keys, or an Array of such
    # Hashes for multiple exception entries.
    class Exception < Base
      trigger_name :exception
      pattern :direct_config
      allowed_keys %i[if message original_failure on_complete on_failure]
      standard_hook_key_types
      key_type :string, :message
      key_type :boolean, :original_failure
    end
  end
end
