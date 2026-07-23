# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the case save trigger.
    # Delegate pattern: nested trigger definitions are validated by TriggerTasks recursively.
    class Case < Base
      trigger_name :case
      pattern :delegate
    end
  end
end
