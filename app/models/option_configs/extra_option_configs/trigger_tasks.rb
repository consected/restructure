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

      validate :validate_tasks_structure

      # Override default field-keyed setup to store the value as a single
      # attribute. Handles both Hash and Array inputs.
      # @return [void]
      def setup_named_configurations
        raw = hash_configuration
        self.tasks = normalize_tasks(raw)
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

      private

      def validate_tasks_structure
        raw = hash_configuration
        return if raw.blank?
        return unless validate_array_or_hash_attribute(:tasks, raw)
        return unless raw.is_a?(Array)

        raw.each_with_index do |item, index|
          next if item.is_a?(Hash)

          add_validation_notice(:tasks, "entry #{index + 1} must be a Hash task definition")
        end
      end

      def normalize_tasks(value)
        return nil if value.nil?

        case value
        when Array
          value.map { |item| normalize_tasks(item) }
        when Hash
          value.each_with_object({}) do |(key, nested_value), normalized|
            normalized[key.to_sym] = normalize_tasks(nested_value)
          end
        else
          if value.respond_to?(:filtered_hash)
            normalize_tasks(value.filtered_hash)
          elsif value.respond_to?(:to_h) && !value.is_a?(String)
            normalize_tasks(value.to_h)
          else
            value
          end
        end
      end
    end
  end
end
