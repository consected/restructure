# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for save trigger cascading.
    # Schema docs: docs/admin_reference/general/save_trigger.md
    # Uses the BaseConfiguration pattern with typed attributes for each
    # trigger key, all typed as TriggerTasks.
    #
    # Handles:
    # - Key validation against ValidSaveTriggerTriggers
    # - on_save cascade to on_create/on_update (wrapping hashes into arrays)
    # - Default blank TriggerTasks for on_upload and on_disable
    #
    # @example
    #   st = SaveTrigger.new(on_save: { notify: { type: 'email' } })
    #   st[:on_create].tasks  #=> [{ notify: { type: 'email' } }]
    class SaveTrigger < BaseConfiguration
      configure_typed_attribute :on_create, type: TriggerTasks
      configure_typed_attribute :on_update, type: TriggerTasks
      configure_typed_attribute :on_save, type: TriggerTasks
      configure_typed_attribute :on_upload, type: TriggerTasks
      configure_typed_attribute :on_disable, type: TriggerTasks
      configure_typed_attribute :before_save, type: TriggerTasks

      validate :validate_keys
      validate :validate_trigger_shapes
      validate :validate_before_save_unsupported_triggers

      # Set up typed attributes with cascade logic.
      # @return [void]
      def setup_named_configurations
        config_hash = hash_configuration.is_a?(Hash) ? hash_configuration.deep_dup : {}
        self.hash_configuration = config_hash
        cascade_on_save

        setup_all_options_typed(config_hash)
        sync_typed_to_configurations
      end

      # Returns true if no trigger tasks are configured on any key.
      def blank?
        self.class.option_types[:typed].all? { |key| send(key).blank? }
      end

      # Trigger names whose config is itself a nested trigger task list, rather than
      # a task's own config - mirrors TriggerTasks#validate_nested_trigger_definitions.
      DELEGATE_TRIGGERS = %i[transaction background].freeze

      private

      # Validate keys against the allowed set.
      # @return [void]
      def validate_keys
        return unless validate_hash_attribute(:save_trigger, raw_configuration)
        return if hash_configuration.keys.empty?

        invalid = hash_configuration.keys - OptionConfigs::ExtraOptions::ValidSaveTriggerTriggers
        return if invalid.empty?

        errors.add(:save_trigger,
                   "contains invalid keys #{hash_configuration.keys} - expected only: #{OptionConfigs::ExtraOptions::ValidSaveTriggerTriggers}")
      end

      def validate_trigger_shapes
        return unless raw_configuration.is_a?(Hash)

        hash_configuration.each do |trigger_name, config|
          next if config.nil? || config.is_a?(Hash) || config.is_a?(Array)

          add_validation_notice(:save_trigger,
                                "#{trigger_name} must be a Hash or Array of Hash task definitions")
        end
      end

      # Warn when before_save configures a trigger that performs a genuine update of
      # the record currently being saved (see issue #1384) - such triggers only work
      # correctly from on_create/on_update/on_disable, once the record is persisted.
      # @return [void]
      def validate_before_save_unsupported_triggers
        return if before_save.blank?

        scan_before_save_tasks(before_save.tasks)
      end

      # @param [Hash, Array, nil] tasks
      # @return [void]
      def scan_before_save_tasks(tasks)
        case tasks
        when Hash
          tasks.each { |trigger_name, config| check_before_save_trigger(trigger_name.to_sym, config) }
        when Array
          tasks.each { |entry| scan_before_save_tasks(entry) if entry.is_a?(Hash) }
        end
      end

      # @param [Symbol] trigger_name
      # @param [Hash, Array] config
      # @return [void]
      def check_before_save_trigger(trigger_name, config)
        case trigger_name
        when :each
          scan_before_save_tasks(config[:do]) if config.is_a?(Hash)
          return
        when :case
          Array(config).each do |branch|
            next unless branch.is_a?(Hash)

            scan_before_save_tasks(branch[:then])
            scan_before_save_tasks(branch[:else])
          end
          return
        when *DELEGATE_TRIGGERS
          scan_before_save_tasks(config)
          return
        end

        warning = OptionConfigs::TriggerTypes::Base.for(trigger_name)&.before_save_warning(config)
        add_validation_notice(:before_save, "#{trigger_name} #{warning}", level: :warn) if warning
      end

      # Cascade on_save into on_create and on_update (wrapping hashes into arrays).
      # Modifies hash_configuration in place before typed attributes are initialized.
      # @return [void]
      def cascade_on_save
        return unless hash_configuration.is_a?(Hash)

        os = hash_configuration[:on_save]
        return unless os

        os = [os] if os.is_a?(Hash)

        oc = hash_configuration[:on_create]
        ou = hash_configuration[:on_update]
        oc = [oc] if oc.is_a?(Hash)
        ou = [ou] if ou.is_a?(Hash)
        oc ||= []
        ou ||= []

        hash_configuration[:on_create] = os + oc
        hash_configuration[:on_update] = os + ou
      end
    end
  end
end
