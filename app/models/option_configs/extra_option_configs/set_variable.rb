# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for variable definitions.
    # Schema docs: docs/admin_reference/general/set_variables.md
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Stores the validated array as a direct attribute.
    #
    # Handles:
    # - Validating set_variables is an array
    # - Validating each entry has :name and :value keys
    # - Filtering out invalid entries
    #
    # @example
    #   sv = SetVariable.new([{ name: 'var1', value: 'val1' }])
    #   sv.set_variables #=> [{ name: 'var1', value: 'val1' }]
    class SetVariable < BaseConfiguration
      configure_direct :set_variables, type: :array

      validate :validate_structure

      def self.store_processed_value?
        true
      end

      # Parse and store the input array.
      # @return [void]
      def setup_named_configurations
        raw = hash_configuration
        if raw.blank?
          self.set_variables = nil
          return
        end

        unless raw.is_a?(Array)
          self.set_variables = []
          return
        end

        self.set_variables = raw.filter_map do |entry|
          entry = entry.symbolize_keys if entry.is_a?(Hash)
          next nil unless entry.is_a?(Hash) && entry[:name].present? && entry.key?(:value)

          entry
        end
      end

      # Returns true when no variables are defined.
      def blank?
        set_variables.blank?
      end

      private

      # Validate set_variables structure.
      # @return [void]
      def validate_structure
        raw = hash_configuration
        return if raw.blank?

        unless raw.is_a?(Array)
          errors.add(:set_variables, 'must be an array of variable definitions')
          return
        end

        raw.each do |entry|
          entry = entry.symbolize_keys if entry.is_a?(Hash)
          next if entry.is_a?(Hash) && entry[:name].present? && entry.key?(:value)

          errors.add(:set_variables, "each entry must have 'name' and 'value' keys")
        end
      end
    end
  end
end
