# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for save trigger cascading.
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

      # Set up typed attributes with cascade logic.
      # @return [void]
      def setup_named_configurations
        cascade_on_save

        setup_all_options_typed(hash_configuration)

        # Store the raw tasks values in configurations for hash-like bracket access.
        # Consumers expect raw Array/Hash, not TriggerTasks instances.
        self.class.option_types[:typed].each do |key|
          typed = send(key)
          configurations[key] = typed.respond_to?(:tasks) ? typed.tasks : typed
        end
      end

      # Returns true if no trigger tasks are configured on any key.
      def blank?
        self.class.option_types[:typed].all? { |key| send(key).blank? }
      end

      private

      # Validate keys against the allowed set.
      # @return [void]
      def validate_keys
        return unless hash_configuration.is_a?(Hash)
        return if hash_configuration.keys.empty?

        invalid = hash_configuration.keys - OptionConfigs::ExtraOptions::ValidSaveTriggerTriggers
        return if invalid.empty?

        errors.add(:save_trigger,
                   "contains invalid keys #{hash_configuration.keys} - expected only: #{OptionConfigs::ExtraOptions::ValidSaveTriggerTriggers}")
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
