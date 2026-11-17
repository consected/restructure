# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for batch trigger setup.
    # Schema docs: docs/admin_reference/general/batch_trigger.md
    # Uses the BaseConfiguration pattern with a single typed attribute
    # `:on_record` that is a TriggerTasks instance.
    #
    # @example
    #   bt = BatchTrigger.new(on_record: { notify: { type: 'email' } })
    #   bt[:on_record]         #=> TriggerTasks instance
    #   bt[:on_record].tasks   #=> { notify: { type: 'email' } }
    class BatchTrigger < BaseConfiguration
      configure_typed_attribute :on_record, type: TriggerTasks

      validate :validate_batch_trigger_shape

      # Set up typed attributes from the hash configuration.
      # Delegates to OptionsHandler's setup_all_options_typed which
      # instantiates TriggerTasks for the :on_record key.
      # @return [void]
      def setup_named_configurations
        config_hash = hash_configuration.is_a?(Hash) ? hash_configuration : {}
        setup_all_options_typed(config_hash)
        sync_typed_to_configurations
      end

      # Returns true if there are no trigger tasks configured.
      def blank?
        on_record.blank?
      end

      private

      def validate_batch_trigger_shape
        return unless validate_hash_attribute(:batch_trigger, raw_configuration)

        return unless hash_configuration.key?(:on_record)
        return if hash_configuration[:on_record].is_a?(Hash) || hash_configuration[:on_record].is_a?(Array)

        add_validation_notice(:batch_trigger, 'on_record must be a Hash or Array of Hash task definitions')
      end
    end
  end
end
