# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the log save trigger.
    # Direct-config pattern: config is a Hash of log keys, or an Array of such
    # Hashes for multiple log entries.
    # Runtime: SaveTriggers::Log wraps a single Hash into an array and iterates
    # direct config hashes via extract_config.
    class Log < Base
      trigger_name :log
      pattern :direct_config
      allowed_keys %i[if message severity on_complete on_failure]
      standard_hook_key_types
      key_type :string, :message, :severity
    end
  end
end
