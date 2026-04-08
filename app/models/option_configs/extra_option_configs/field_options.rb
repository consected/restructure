# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for field-level edit options.
    # Schema docs: docs/admin_reference/general/field_options.md
    # Extracted from ExtraOptions#clean_field_options_def
    #
    # Values are per-field option hashes keyed by field name.
    # Handles converting edit_as.alt_options from Array to Hash.
    class FieldOptions < BaseConfiguration
      # Named configuration for a single field's options.
      class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
        configure_attributes %i[
          include_blank pattern value blank_value preset_value blank_preset_value
          active_value no_downcase view_original_case view_with_formats format
          config edit_as calculate_with prompt use_app_type selected show_expanded
          keep_label
        ]
      end

      value_pattern :field_option_hash,
                    description: 'Per-field option hash with edit behavior settings',
                    match: Hash,
                    allowed_keys: NamedConfiguration.option_types[:simple]

      validate :validate_field_key_names
      validate :validate_value_patterns

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
