# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for field-level edit options.
    # Extracted from ExtraOptions#clean_field_options_def
    #
    # Values are arbitrary option hashes keyed by field name.
    # Handles converting edit_as.alt_options from Array to Hash.
    class FieldOptions < BaseConfiguration
      # No NamedConfiguration — values are arbitrary option hashes

      # Override to preprocess alt_options arrays.
      def add_named_configuration(sym_key, value)
        super(sym_key, preprocess_field(value))
      end

      private

      # Convert edit_as.alt_options from Array to Hash if needed.
      # @param [Object] value - raw field option value
      # @return [Object] processed value
      def preprocess_field(value)
        return value unless value.is_a?(Hash)

        ao = value.dig(:edit_as, :alt_options)
        return value unless ao.is_a?(Array)

        new_ao = {}
        ao.each { |aov| new_ao[aov.to_s.to_sym] = aov.to_s.downcase }
        value[:edit_as][:alt_options] = new_ao
        value
      end
    end
  end
end
