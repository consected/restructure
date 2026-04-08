# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for caption formatting (text-to-HTML conversion).
    # Schema docs: docs/admin_reference/general/caption_before.md
    # Extracted from ExtraOptions#clean_caption_before_def
    #
    # Each field name maps to a NamedConfiguration with caption mode attributes.
    # Preprocessing (string → hash expansion, text_to_html conversion) happens
    # via add_named_configuration override.
    class CaptionBefore < BaseConfiguration
      # Pseudo-keys allowed in caption_before that are not actual field names.
      PSEUDO_KEYS = %i[all_fields submit].freeze

      # Named configuration for a single field's caption settings.
      # Each field (e.g. :test1) has caption values for different display modes.
      class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
        configure_attributes %i[caption edit_caption show_caption new_caption keep_label]
      end

      ALLOWED_VALUE_KEYS = NamedConfiguration.option_types[:simple].freeze

      validate :validate_caption_before_entries

      # Receive parent context to capture valid field names for key validation.
      # Called by ExtraOptions before initialization; fields is already populated.
      # @param raw [Hash, nil] raw caption_before config
      # @param parent [ExtraOptions] parent options with fields list
      # @return [Hash] raw config (unchanged), with _valid_fields metadata
      def self.prepare_config(raw, parent)
        return raw unless raw.is_a?(Hash)

        valid_fields = parent.fields || []
        raw[:_valid_fields] = valid_fields
        raw
      end

      # Override to preprocess caption values before creating NamedConfiguration.
      # Handles string → hash expansion and text_to_html conversion.
      def add_named_configuration(sym_key, value)
        return if sym_key == :_valid_fields

        super(sym_key, preprocess_field(value))
      end

      private

      # Validate each entry's value type and key name.
      def validate_caption_before_entries
        return unless hash_configuration.is_a?(Hash)

        valid_fields = hash_configuration[:_valid_fields]
        hash_configuration.each do |field_name, value|
          next if field_name == :_valid_fields

          validate_entry_value(field_name, value)
          validate_key_name(field_name, valid_fields) if valid_fields
        end
      end

      # Validate that a caption value is String or Hash with allowed keys.
      def validate_entry_value(field_name, value)
        return if value.is_a?(String) || value.is_a?(Hash)

        add_validation_notice(field_name, "#{field_name} must be a String or Hash, got #{value.class}")
      end

      # Validate that the key name is a valid field name, pseudo-key, or reference_ prefix.
      def validate_key_name(field_name, valid_fields)
        return if PSEUDO_KEYS.include?(field_name)
        return if field_name.to_s.start_with?('reference_')
        return if valid_fields.include?(field_name.to_s)

        add_validation_notice(field_name,
                              "#{field_name} is not a valid field name, pseudo-key (all_fields, submit), " \
                              'or reference_ prefixed key',
                              level: :warn)
      end

      # Pre-process a single field's raw value into a hash suitable for NamedConfiguration.
      # - String values are expanded to all 4 caption mode keys with HTML conversion
      # - Hash values have text_to_html applied to each mode value
      # - new_caption defaults to edit_caption when not specified
      # @param [String | Hash] value - raw caption value
      # @return [Hash{Symbol => String}] processed hash with caption mode keys
      def preprocess_field(value)
        if value.is_a?(String)
          html = Formatter::Substitution.text_to_html(value).strip
          { caption: html, edit_caption: html, show_caption: html, new_caption: html }
        elsif value.is_a?(Hash)
          processed = {}
          value.each { |mode, modeval| processed[mode.to_sym] = Formatter::Substitution.text_to_html(modeval).to_s.strip }
          processed[:new_caption] = processed[:edit_caption] unless processed.key?(:new_caption)
          processed
        else
          {}
        end
      end
    end
  end
end
