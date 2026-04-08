# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    module Concerns
      # Provides class-level DSLs for declaring extra key patterns and value patterns
      # on field-keyed BaseConfiguration subclasses.
      #
      # == Extra Keys
      #
      # Declares non-field key names that are valid for this config class.
      # Accepts symbols (exact match) and regexes (pattern match):
      #
      #   extra_keys :all_fields, :submit, /\Areference_/
      #
      # == Value Patterns
      #
      # Declares named value shapes that entries can take. Each pattern carries:
      # - +match+: Class, Array of Classes, or Proc for type discrimination
      # - +allowed_keys+: (Hash patterns) valid keys within the hash value
      # - +required_keys+: (Hash patterns) keys that must be present
      # - +description+: human-readable description for future UI guidance
      #
      #   value_pattern :simple_caption,
      #     description: 'Simple caption string',
      #     match: String
      #
      #   value_pattern :caption_hash,
      #     description: 'Caption hash with optional view-specific modes',
      #     match: Hash,
      #     allowed_keys: %i[caption show_caption edit_caption new_caption keep_label]
      #
      # == Automatic Validation
      #
      # When +_valid_fields+ metadata is present (injected by +prepare_config+),
      # +validate_field_key_names+ checks each entry's key against extra_keys
      # and the valid field list.
      #
      # +validate_value_patterns+ checks each entry's value against declared patterns,
      # reporting errors for values that match no pattern, warnings for unrecognized
      # hash keys, and errors for missing required keys.
      module PatternValidation
        extend ActiveSupport::Concern

        VALID_FIELDS_KEY = :_valid_fields

        included do
          class_attribute :_extra_keys, default: []
          class_attribute :_value_patterns, default: {}
        end

        class_methods do
          # Declare extra key names or patterns that are valid beyond field names.
          # @param keys [Array<Symbol, Regexp>] exact symbols or regex patterns
          def extra_keys(*keys)
            self._extra_keys = keys.freeze
          end

          # Declare a named value pattern for entries in this config.
          # @param name [Symbol] unique pattern identifier
          # @param description [String] human-readable pattern description
          # @param match [Class, Array<Class>, Proc] type discriminator
          # @param allowed_keys [Array<Symbol>, nil] valid hash keys (Hash patterns only)
          # @param required_keys [Array<Symbol>, nil] mandatory hash keys (Hash patterns only)
          def value_pattern(name, description:, match:, allowed_keys: nil, required_keys: nil)
            self._value_patterns = _value_patterns.merge(
              name => {
                description:,
                match:,
                allowed_keys: allowed_keys&.freeze,
                required_keys: required_keys&.freeze
              }
            ).freeze
          end

          # Default prepare_config that injects _valid_fields from parent context.
          # Only injects when the class has registered validate_field_key_names,
          # avoiding pollution of non-field-keyed classes (ViewOptions, Filestore, etc.).
          # Subclasses with custom prepare_config should call super or inject _valid_fields.
          # @param raw [Hash, nil] raw config hash
          # @param parent [ExtraOptions] parent options instance
          # @return [Object] raw config with _valid_fields metadata
          def prepare_config(raw, parent)
            return raw unless raw.is_a?(Hash)
            return raw unless uses_field_key_validation?

            raw[VALID_FIELDS_KEY] = parent.fields || []
            raw
          end

          # Whether this class has registered validate_field_key_names in its callbacks.
          # @return [Boolean]
          def uses_field_key_validation?
            _validate_callbacks.any? { |cb| cb.filter == :validate_field_key_names }
          end
        end

        # Check whether a field key matches any declared extra_keys entry.
        # @param field_name [Symbol] the key to check
        # @return [Boolean]
        def extra_key?(field_name)
          self.class._extra_keys.any? do |key|
            key.is_a?(Regexp) ? key.match?(field_name.to_s) : key == field_name
          end
        end

        # Validate all entry keys against valid field names and extra_keys.
        # Skips validation when _valid_fields metadata is not present.
        # Reports unrecognized keys as warnings.
        def validate_field_key_names
          return unless hash_configuration.is_a?(Hash)

          valid_fields = hash_configuration[VALID_FIELDS_KEY]
          return unless valid_fields

          each_config_entry do |field_name, _value|
            next if extra_key?(field_name)
            next if valid_fields.include?(field_name.to_s)

            extra_keys_desc = self.class._extra_keys.map { |k| k.is_a?(Regexp) ? k.inspect : k }.join(', ')
            add_validation_notice(field_name,
                                  "#{field_name} is not a valid field name" \
                                  "#{extra_keys_desc.present? ? " or extra key (#{extra_keys_desc})" : ''}",
                                  level: :warn)
          end
        end

        # Validate all entry values against declared value patterns.
        # When no patterns are declared, no value type validation occurs.
        # Reports errors for values matching no pattern, warns on unrecognized hash keys,
        # errors on missing required keys.
        def validate_value_patterns
          return unless hash_configuration.is_a?(Hash)
          return if self.class._value_patterns.empty?

          each_config_entry do |field_name, value|
            matched = match_value_pattern(value)
            unless matched
              types = self.class._value_patterns.values.map { |p| describe_match(p[:match]) }.join(' or ')
              add_validation_notice(field_name,
                                    "#{field_name} must be #{types}, got #{value.class}")
              next
            end

            validate_pattern_constraints(field_name, value, matched)
          end
        end

        # Find the first matching value pattern for a given value.
        # @param value [Object] the entry value
        # @return [Hash, nil] the matched pattern definition, or nil
        def match_value_pattern(value)
          self.class._value_patterns.each_value do |pattern|
            return pattern if value_matches?(value, pattern[:match])
          end
          nil
        end

        private

        # Iterate hash_configuration entries, skipping metadata keys.
        def each_config_entry
          hash_configuration.each do |field_name, value|
            next if field_name == VALID_FIELDS_KEY

            yield field_name, value
          end
        end

        # Test whether a value matches a pattern's match spec.
        def value_matches?(value, match_spec)
          case match_spec
          when Class
            value.is_a?(match_spec)
          when Array
            match_spec.any? { |klass| value.is_a?(klass) }
          when Proc
            match_spec.call(value)
          else
            false
          end
        end

        # Apply constraints from a matched pattern (allowed_keys, required_keys).
        def validate_pattern_constraints(field_name, value, pattern)
          return unless value.is_a?(Hash)

          if pattern[:allowed_keys]
            invalid = value.keys.map(&:to_sym) - pattern[:allowed_keys]
            if invalid.present?
              add_validation_notice(field_name,
                                    "#{field_name} contains unrecognized keys #{invalid}",
                                    level: :warn)
            end
          end

          return unless pattern[:required_keys]

          missing = pattern[:required_keys] - value.keys.map(&:to_sym)
          return if missing.empty?

          add_validation_notice(field_name,
                                "#{field_name} is missing required keys #{missing}")
        end

        # Human-readable description of a match spec.
        def describe_match(match_spec)
          case match_spec
          when Class
            match_spec.name
          when Array
            match_spec.map(&:name).join(' or ')
          when Proc
            'a valid value'
          else
            match_spec.to_s
          end
        end
      end
    end
  end
end
