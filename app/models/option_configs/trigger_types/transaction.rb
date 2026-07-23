# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the transaction save trigger.
    # Delegate pattern: nested trigger definitions are validated by TriggerTasks recursively.
    class Transaction < Base
      trigger_name :transaction
      pattern :delegate
    end
  end
end
