# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for creatable_if access control condition.
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Split from AccessIf to manage a single if_condition directly.
    # The processed hash is stored back on the parent ExtraOptions (not the object).
    class CreatableIf < BaseConfiguration
      configure_direct :creatable_if, type: :hash

      def self.store_processed_value?
        true
      end

      # Store the symbolized hash value, defaulting to empty hash.
      # Populate configurations for hash-like bracket access.
      # @return [void]
      def setup_named_configurations
        self.creatable_if = hash_configuration.presence || {}
        creatable_if.each { |k, v| configurations[k] = v }
      end
    end
  end
end
