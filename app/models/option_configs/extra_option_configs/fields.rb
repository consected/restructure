# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for field list setup.
    # Schema docs: docs/admin_reference/general/fields.md
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Stores the field list as a direct array value.
    # The processed array is stored back on the parent ExtraOptions (not the object).
    class Fields < BaseConfiguration
      configure_direct :fields, type: :array

      def self.store_processed_value?
        true
      end

      # Store the array value, defaulting to empty array.
      # @return [void]
      def setup_named_configurations
        self.fields = hash_configuration.is_a?(Array) ? hash_configuration : []
      end
    end
  end
end
