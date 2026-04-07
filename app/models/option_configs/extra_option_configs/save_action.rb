# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for save action cascading (on_save -> on_create/on_update).
    # Schema docs: docs/admin_reference/general/save_action.md
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Stores the entire hash as a single direct attribute after cascading.
    #
    # Handles:
    # - on_save cascade to on_create and on_update (hash merge)
    #
    # @example
    #   sa = SaveAction.new(on_save: { label: 'Saved' })
    #   sa.save_action[:on_create] #=> { label: 'Saved' }
    class SaveAction < BaseConfiguration
      configure_direct :save_action, type: :hash

      # Store the input hash with on_save cascade applied
      # and populate configurations for hash-like [] access.
      # @return [void]
      def setup_named_configurations
        sa = hash_configuration.presence || {}
        cascade_on_save(sa)
        self.save_action = sa
        sa.each { |k, v| configurations[k] = v }
      end

      private

      # Cascade on_save into on_create and on_update as defaults.
      # on_save values are merged as base, with specific key values taking priority.
      # @param [Hash] sa - the save_action hash (modified in place)
      # @return [void]
      def cascade_on_save(sa)
        os = sa[:on_save]
        return unless os

        ou = sa[:on_update] || {}
        oc = sa[:on_create] || {}
        sa[:on_update] = os.merge(ou)
        sa[:on_create] = os.merge(oc)
      end
    end
  end
end
