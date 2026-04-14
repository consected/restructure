# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the log save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class Log < Base
      trigger_name :log
      pattern :named_entry
      allowed_keys %i[if message severity on_complete on_failure]
      key_type :string, :message, :severity
    end
  end
end
