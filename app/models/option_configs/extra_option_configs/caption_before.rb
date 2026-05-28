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

      # Library _default blocks legitimately inject caption_before entries for
      # fields absent from this particular model. Skip those warnings.
      lenient_field_key_names!

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
                    allowed_keys: NamedConfiguration.option_types[:simple],
                    key_types: {
                      caption: :string,
                      edit_caption: :string,
                      show_caption: :string,
                      new_caption: :string,
                      keep_label: :boolean
                    }

      validate :validate_field_key_names
      validate :validate_value_patterns

      # Override default setup so that hash_configuration carries the
      # preprocessed (HTML-converted, defaulted, coerced) values into the
      # validation pass. This preserves the historical lenience of accepting
      # `keep_label: 'true'`, `new_caption: ` (nil), or a bare String caption.
      # @return [void]
      def setup_named_configurations
        return unless hash_configuration.is_a?(Hash)

        nil_keys = []
        hash_configuration.each do |k, v|
          next if k == Concerns::PatternValidation::VALID_FIELDS_KEY
          next if k == Concerns::PatternValidation::DECLARED_FIELDS_KEY

          # A nil value clears any library-default caption for this field.
          # Collect for removal so we don't modify the hash mid-iteration.
          if v.nil?
            nil_keys << k
            next
          end

          processed = preprocess_field(v)
          hash_configuration[k] = processed if processed.is_a?(Hash) && !processed.empty?
          add_named_configuration(k.to_sym, v)
        end

        nil_keys.each { |k| hash_configuration.delete(k) }
      end

      # Override to preprocess caption values before creating NamedConfiguration.
      # Handles string → hash expansion and text_to_html conversion.
      def add_named_configuration(sym_key, value)
        super(sym_key, preprocess_field(value))
      end

      private

      # Pre-process a single field's raw value into a hash suitable for NamedConfiguration.
      # - String values are expanded to all 4 caption mode keys with HTML conversion
      # - Hash values have text_to_html applied to each caption-mode value (skipping
      #   non-caption keys such as :keep_label which carry boolean values)
      # - new_caption is dropped when blank/nil and defaulted from edit_caption,
      #   then from caption, so that an explicit `new_caption: ` (nil) entry in
      #   YAML does not produce a type-validation failure.
      # - keep_label accepts the strings 'true'/'false' as well as real booleans.
      # @param [String | Hash] value - raw caption value
      # @return [Hash{Symbol => Object}] processed hash with caption mode keys
      def preprocess_field(value)
        if value.is_a?(String)
          html = Formatter::Substitution.text_to_html(value).strip
          { caption: html, edit_caption: html, show_caption: html, new_caption: html }
        elsif value.is_a?(Hash)
          caption_modes = %i[caption edit_caption show_caption new_caption]
          processed = {}
          value.each do |mode, modeval|
            mode_sym = mode.to_sym
            if caption_modes.include?(mode_sym)
              next if modeval.nil? || modeval == ''

              processed[mode_sym] = Formatter::Substitution.text_to_html(modeval).to_s.strip
            elsif mode_sym == :keep_label
              processed[mode_sym] = coerce_keep_label(modeval)
            else
              processed[mode_sym] = modeval
            end
          end
          unless processed.key?(:new_caption)
            processed[:new_caption] = processed[:edit_caption] || processed[:caption]
          end
          processed.compact
        else
          {}
        end
      end

      # Coerce keep_label to a real boolean. Accepts true/false and the strings
      # 'true'/'false' (case-insensitive). Returns nil for unrecognised input
      # so that type validation can surface a clear error.
      # @param [Object] value
      # @return [Boolean, nil]
      def coerce_keep_label(value)
        case value
        when true, false then value
        when String
          case value.downcase
          when 'true' then true
          when 'false' then false
          else value
          end
        else
          value
        end
      end
    end
  end
end
