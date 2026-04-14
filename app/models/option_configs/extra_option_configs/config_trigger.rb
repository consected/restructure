# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for config trigger setup.
    # Schema docs: docs/admin_reference/general/config_trigger.md
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Uses a typed TriggerTasks attribute for on_define.
    #
    # Handles:
    # - Wrapping a single on_define hash in an array
    # - Defaulting on_define to an empty TriggerTasks when not provided
    #
    # @example
    #   ct = ConfigTrigger.new(on_define: [{ action: 'do_something' }])
    #   ct.on_define.tasks #=> [{ action: 'do_something' }]
    class ConfigTrigger < BaseConfiguration
      configure_typed_attribute :on_define, type: TriggerTasks

      # Preprocess on_define (wrap non-array in array, default to empty)
      # then delegate to typed attribute initialization.
      # @return [void]
      def setup_named_configurations
        od = hash_configuration[:on_define]
        od = [od] if od.is_a?(Hash)
        hash_configuration[:on_define] = od || []

        setup_all_options_typed(hash_configuration)
        sync_typed_to_configurations
      end

      # Returns true when on_define has no tasks.
      def blank?
        on_define.blank?
      end
    end
  end
end
