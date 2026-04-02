# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for batch trigger setup.
    # Uses the BaseConfiguration pattern with a single typed attribute
    # `:on_record` that is a TriggerTasks instance.
    #
    # @example
    #   bt = BatchTrigger.new(on_record: { notify: { type: 'email' } })
    #   bt[:on_record]         #=> TriggerTasks instance
    #   bt[:on_record].tasks   #=> { notify: { type: 'email' } }
    class BatchTrigger < BaseConfiguration
      configure_typed_attribute :on_record, type: TriggerTasks

      # Set up typed attributes from the hash configuration.
      # Delegates to OptionsHandler's setup_all_options_typed which
      # instantiates TriggerTasks for the :on_record key.
      # @return [void]
      def setup_named_configurations
        setup_all_options_typed(hash_configuration)
        # Store the raw tasks value in configurations for hash-like access.
        # Consumers expect raw Array/Hash, not TriggerTasks instance.
        configurations[:on_record] = on_record.respond_to?(:tasks) ? on_record.tasks : on_record
      end

      # Returns true if there are no trigger tasks configured.
      def blank?
        on_record.blank?
      end
    end
  end
end
