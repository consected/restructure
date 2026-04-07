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
      # Named configuration for a single field's dialog settings.
      class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
        configure_attributes %i[name label keep_label]
      end

      validate :validate_dialog_entries

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

      # Validate dialog_before entries via ActiveModel validate callback.
      # Checks for invalid types and missing message templates.
      def validate_dialog_entries
        return if hash_configuration.blank?

        hash_configuration.each do |key, value|
          unless value.is_a?(String) || value.is_a?(Hash)
            errors.add(:dialog_before,
                       "must be a Hash { name: '<template name>' } or String: #{key}")
            next
          end

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
