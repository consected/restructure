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
      configure_direct :tasks, type: :array_or_hash

      validate :validate_tasks_structure
      validate :validate_trigger_actions

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

      # Validates the raw input is a Hash or Array of Hashes.
      # @return [void]
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

      # Validates trigger action names and their configuration keys.
      # @return [void]
      def validate_trigger_actions
        return if tasks.blank?

        case tasks
        when Hash
          validate_trigger_hash(tasks)
        when Array
          tasks.each { |entry| validate_trigger_hash(entry) if entry.is_a?(Hash) }
        end
      end

      # Validates each trigger name in a hash against ValidSaveTriggers.
      # Also handles the special +each:+ iterator key, which is not a trigger
      # action name but a loop construct accepted by +iterate_triggers_for_action+.
      # @param hash [Hash] a single trigger task hash
      # @return [void]
      def validate_trigger_hash(hash)
        hash.each do |trigger_name, config|
          if trigger_name.to_sym == :each
            validate_each_iterator(config)
            next
          end

          trigger_type = OptionConfigs::TriggerTypes::Base.for(trigger_name)
          unless trigger_type
            add_validation_notice(:tasks, "unrecognized trigger action name: #{trigger_name}", level: :warn)
            next
          end

          if trigger_type.pattern == :delegate
            validate_nested_trigger_definitions(trigger_name, config)
          else
            validate_trigger_keys(trigger_name, trigger_type, config)
          end
        end
      end

      # Validates an +each:+ iterator block.
      # Accepted keys are +value+, +if+, and +do+.  The +do+ value is itself
      # a trigger task list (Hash or Array of Hashes) and is validated recursively.
      # @param config [Hash] the iterator configuration
      # @return [void]
      def validate_each_iterator(config)
        return unless config.is_a?(Hash)

        invalid_keys = config.keys.map(&:to_sym) - %i[value if do]
        invalid_keys.each do |k|
          add_validation_notice(:tasks, "each iterator has unrecognized key: #{k}", level: :warn)
        end

        validate_nested_trigger_task_list(config[:do]) if config.key?(:do)
      end

      # Recursively validates nested trigger definitions for delegate-pattern triggers
      # (transaction, background, case). The nested content is itself a trigger task list
      # (or, for case, a list of when/then/else branches whose then/else are trigger task lists).
      # @param trigger_name [Symbol] the delegate trigger name
      # @param config [Object] the nested config value
      # @return [void]
      def validate_nested_trigger_definitions(trigger_name, config)
        case trigger_name.to_sym
        when :case
          validate_case_branches(config)
        else
          validate_nested_trigger_task_list(config)
        end
      end

      # Validates a list (Hash or Array of Hashes) of nested trigger tasks.
      # @param value [Hash, Array] nested trigger task list
      # @return [void]
      def validate_nested_trigger_task_list(value)
        case value
        when Hash
          validate_trigger_hash(value)
        when Array
          value.each { |entry| validate_trigger_hash(entry) if entry.is_a?(Hash) }
        end
      end

      # Validates the branches of a case trigger, recursing into then/else trigger lists.
      # @param value [Hash, Array<Hash>] the case branches
      # @return [void]
      def validate_case_branches(value)
        branches = value.is_a?(Array) ? value : [value]
        branches.each do |branch|
          next unless branch.is_a?(Hash)

          validate_nested_trigger_task_list(branch[:then]) if branch.key?(:then)
          validate_nested_trigger_task_list(branch[:else]) if branch.key?(:else)
        end
      end

      # Validates configuration keys for a specific trigger action.
      # @param trigger_name [Symbol] the trigger action name
      # @param trigger_type [Class] the trigger descriptor class
      # @param config [Hash] the trigger's configuration
      # @return [void]
      def validate_trigger_keys(trigger_name, trigger_type, config)
        warnings = trigger_type.validate_config(config)
        warnings.each do |warning|
          add_validation_notice(:tasks, "#{trigger_name} #{warning}", level: :warn)
        end
      end

      # Recursively normalizes task values, symbolizing hash keys.
      # @param value [Object] the value to normalize
      # @return [Hash, Array, Object, nil]
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
