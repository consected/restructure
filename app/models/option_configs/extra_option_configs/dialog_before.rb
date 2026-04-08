# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for dialog overlay definitions.
    # Schema docs: docs/admin_reference/general/dialog_before.md
    # Extracted from ExtraOptions#clean_dialog_before_def
    #
    # Each field name maps to a NamedConfiguration with dialog attributes.
    # String values are expanded to { name: string } hashes.
    # Validates that referenced Admin::MessageTemplate records exist.
    class DialogBefore < BaseConfiguration
      extra_keys :all_fields, :submit

      # Named configuration for a single field's dialog settings.
      class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
        configure_attributes %i[name label keep_label]
      end

      value_pattern :simple_template,
                    description: 'Template name string',
                    match: String

      value_pattern :dialog_hash,
                    description: 'Dialog hash with template name and label',
                    match: Hash,
                    allowed_keys: NamedConfiguration.option_types[:simple],
                    required_keys: %i[name]

      validate :validate_field_key_names
      validate :validate_value_patterns
      validate :validate_dialog_template_existence

      # Override to preprocess and validate dialog values.
      # Converts strings to { name: string } hashes, validates template existence.
      def add_named_configuration(sym_key, value)
        processed = preprocess_field(sym_key, value)
        return unless processed

        super(sym_key, processed)
      end

      private

      # Pre-process a single dialog_before value.
      # @param [Symbol] key - field name (used in error messages)
      # @param [String | Hash] value - raw dialog value
      # @return [Hash | nil] processed hash, or nil if invalid
      def preprocess_field(key, value)
        if value.is_a?(String)
          { name: value }
        elsif value.is_a?(Hash)
          value.symbolize_keys
        else
          nil
        end
      end

      # Validate that referenced Admin::MessageTemplate records exist.
      # Value type and key validation is handled by PatternValidation.
      def validate_dialog_template_existence
        return if hash_configuration.blank?

        each_config_entry do |key, value|
          next unless value.is_a?(String) || value.is_a?(Hash)

          processed = value.is_a?(String) ? { name: value } : value.symbolize_keys
          name = processed[:name]
          next unless name

          mt = Admin::MessageTemplate.active.find_by(name:)
          next if mt

          errors.add(:dialog_before,
                     "specifies a named message template that doesn't exist: #{name}",
                     type: :warning)
        end
      end
    end
  end
end
