# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Reusable configuration class for trigger task hashes or arrays.
    # Used by BatchTrigger (on_record), SaveTrigger (on_create, on_update, etc.)
    # to store trigger task configurations.
    #
    # Accepts either a Hash or an Array of trigger task hashes.
    # Hash values get symbolized keys; arrays are stored as-is.
    #
    # @example Hash input
    #   tasks = TriggerTasks.new(notify: { type: 'email' }, update_this: { field: 'val' })
    #   tasks.tasks  #=> { notify: { type: 'email' }, update_this: { field: 'val' } }
    #
    # @example Array input
    #   tasks = TriggerTasks.new([{ notify: { type: 'email' } }])
    #   tasks.tasks  #=> [{ notify: { type: 'email' } }]
    class TriggerTasks < BaseConfiguration
      configure_direct :tasks, type: :hash

      # Override default field-keyed setup to store the value as a single
      # attribute. Handles both Hash and Array inputs.
      # @return [void]
      def setup_named_configurations
        raw = hash_configuration
        self.tasks = if raw.is_a?(Array)
                       raw
                     else
                       (raw || {}).symbolize_keys
                     end
      end

      # Returns true when no tasks are defined.
      def blank?
        tasks.blank?
      end

      # Returns the tasks value for backward compatibility.
      # @return [Hash{Symbol => Object}, Array]
      def symbolize_keys
        tasks || {}
      end
    end
  end
end
