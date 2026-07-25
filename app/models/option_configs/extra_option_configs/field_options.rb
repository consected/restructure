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

      # Library _default blocks legitimately inject field_options entries for
      # fields absent from this particular model. Skip those warnings.
      lenient_field_key_names!
      class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
        # Additional pass-through attributes that are allowed in field_options
        # but cannot be created as accessor attributes (either because they
        # collide with reserved Ruby methods such as `class`, or because they
        # are HTML-input hints handled downstream).
        EXTRA_PASSTHROUGH_KEYS = %i[class capitalize default_value min max placeholder step].freeze

        configure_attributes %i[
          include_blank pattern value blank_value preset_value blank_preset_value
          active_value no_downcase view_original_case view_with_formats format
          config edit_as calculate_with prompt use_app_type selected show_expanded
          keep_label
        ]

        # Override recognized-key validation to additionally accept
        # EXTRA_PASSTHROUGH_KEYS without requiring accessor attributes.
        def validate_recognized_keys
          return unless hash_configuration.is_a?(Hash)
          return unless owner&.respond_to?(:failed_config, true)

          recognized = self.class.option_types[:simple].to_set + EXTRA_PASSTHROUGH_KEYS
          hash_configuration.each_key do |key|
            next if recognized.include?(key)

            owner.send(:failed_config, key, "unrecognized attribute '#{key}'", level: :warn)
          end
        end
      end

      value_pattern :field_option_hash,
                    description: 'Per-field option hash with edit behavior settings',
                    match: Hash,
                    allowed_keys: NamedConfiguration.option_types[:simple] +
                                  NamedConfiguration::EXTRA_PASSTHROUGH_KEYS,
                    key_types: {
                      include_blank: :boolean,
                      no_downcase: :boolean,
                      view_original_case: :boolean,
                      show_expanded: :boolean,
                      keep_label: :boolean,
                      capitalize: :boolean,
                      pattern: :string,
                      # active_value can be a literal string, a '{{substitution}}'
                      # string, or a Hash with return_value lookup form
                      # (e.g. { this: { field_name: return_value } }) so that
                      # field defaults can be derived from other record values.
                      # value, blank_value, preset_value, blank_preset_value all
                      # accept the same Hash return_value lookup form as active_value
                      # (e.g. { this: { model: { field: return_value } } })
                      # They also accept an Array of strings for multi-value presets.
                      value: :string_hash_or_array,
                      blank_value: :string_hash_or_array,
                      preset_value: :string_hash_or_array,
                      blank_preset_value: :string_hash_or_array,
                      active_value: :string_or_hash,
                      format: :string,
                      class: :string,
                      placeholder: :string,
                      default_value: :string,
                      edit_as: :hash,
                      config: :hash
                    }

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

        edit_as = value[:edit_as]
        return value unless edit_as.is_a?(Hash)

        ao = edit_as[:alt_options]
        return value unless ao.is_a?(Array)

        new_ao = {}
        ao.each { |aov| new_ao[aov.to_s.to_sym] = aov.to_s.downcase }
        value[:edit_as][:alt_options] = new_ao
        value
      end
    end
  end
end
