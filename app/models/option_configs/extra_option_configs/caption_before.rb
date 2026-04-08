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
      extra_keys :all_fields, :submit, /\Areference_/

      # Named configuration for a single field's caption settings.
      # Each field (e.g. :test1) has caption values for different display modes.
      class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
        configure_attributes %i[caption edit_caption show_caption new_caption keep_label]
      end

      value_pattern :simple_caption,
                    description: 'Simple caption string',
                    match: String

      value_pattern :caption_hash,
                    description: 'Caption hash with optional view-specific modes',
                    match: Hash,
                    allowed_keys: NamedConfiguration.option_types[:simple]

      validate :validate_field_key_names
      validate :validate_value_patterns

      # Override to preprocess caption values before creating NamedConfiguration.
      # Handles string → hash expansion and text_to_html conversion.
      def add_named_configuration(sym_key, value)
        super(sym_key, preprocess_field(value))
      end

      private

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
