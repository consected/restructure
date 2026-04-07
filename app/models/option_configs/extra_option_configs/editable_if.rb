# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for editable_if access control condition.
    # Schema docs: docs/admin_reference/general/editable_if.md
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Split from AccessIf to manage a single if_condition directly.
    # The processed hash is stored back on the parent ExtraOptions (not the object).
    class EditableIf < BaseConfiguration
      configure_direct :editable_if, type: :hash

      validate :validate_editable_if_shape

      def self.store_processed_value?
        true
      end

      # Store the symbolized hash value, defaulting to empty hash.
      # Populate configurations for hash-like bracket access.
      # @return [void]
      def setup_named_configurations
        self.editable_if = hash_configuration.is_a?(Hash) ? (hash_configuration.presence || {}) : {}
        editable_if.each { |k, v| configurations[k] = v }
      end

      private

      def validate_editable_if_shape
        validate_hash_attribute(:editable_if, hash_configuration)
      end
    end
  end
end
