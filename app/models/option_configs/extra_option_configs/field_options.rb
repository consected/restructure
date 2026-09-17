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
        configure_attributes %i[
          include_blank pattern value blank_value preset_value blank_preset_value
          active_value no_downcase view_original_case view_with_formats format
          config edit_as calculate_with prompt use_app_type selected show_expanded
          keep_label disabled
        ]

        # Any key/value pair is historically valid in field_options and passed through
        # to the HTML input (see CommonTemplatesHelper#field_options_for and
        # edit_fields/_default.html.erb), so unlike other NamedConfiguration subclasses,
        # keys not declared above are never reported as unrecognized (issue #1456).
        def validate_recognized_keys; end

        # Forward raw keys that aren't declared accessor attributes (e.g. `class`,
        # `placeholder`, `min`, `max`, `step`, or any other HTML attribute) so they
        # still reach the rendered form field via #dup/#filtered_hash.
        def to_h
          super.merge(hash_configuration.except(*self.class.option_types[:simple]))
        end

        # Rebind to_hash to this class's own #to_h — the inherited `alias to_hash to_h`
        # in BaseNamedConfiguration is bound to the pre-override implementation.
        alias to_hash to_h
      end

      value_pattern :field_option_hash,
                    description: 'Per-field option hash with edit behavior settings',
                    match: Hash,
                    # No allowed_keys restriction: any key is valid HTML pass-through
                    # for field_options (see NamedConfiguration#validate_recognized_keys).
                    key_types: {
                      include_blank: :boolean_or_string,
                      no_downcase: :boolean,
                      disabled: :boolean,
                      view_original_case: :boolean,
                      show_expanded: :boolean,
                      keep_label: :boolean,
                      capitalize: :boolean,
                      pattern: :string,
                      # All field value options accept literal strings, booleans,
                      # numerics, return_value Hash lookups, and arrays of strings.
                      value: :boolean_numeric_string_hash_or_array,
                      blank_value: :boolean_numeric_string_hash_or_array,
                      preset_value: :boolean_numeric_string_hash_or_array,
                      blank_preset_value: :boolean_numeric_string_hash_or_array,
                      active_value: :boolean_numeric_string_hash_or_array,
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
