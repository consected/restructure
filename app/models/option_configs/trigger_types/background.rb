# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the background save trigger.
    # Delegate pattern: nested trigger definitions are validated by TriggerTasks recursively.
    class Background < Base
      trigger_name :background
      pattern :delegate
    end
  end
end
