# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    module Concerns
      # Provides class-level DSLs for declaring extra key patterns, value patterns,
      # and key type constraints on field-keyed BaseConfiguration subclasses.
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
      # - +key_types+: (Hash patterns) per-key type constraints (see Key Types below)
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
      #   value_pattern :column_config,
      #     description: 'Column configuration hash',
      #     match: Hash,
      #     allowed_keys: %i[type array index encrypted],
      #     key_types: { type: :string, array: :boolean, index: :boolean, encrypted: :boolean }
      #
      # When both +allowed_keys+ and +key_types+ are provided, a consistency check
      # ensures every +key_types+ key is present in +allowed_keys+. A mismatch raises
      # +ArgumentError+ at class load time.
      #
      # == Key Types (top-level)
      #
      # Declares type constraints on top-level hash_configuration keys.
      # The allowed keys are derived automatically from all declarations.
      #
      #   key_type :boolean, %i[use_current_version prevent_migrations]
      #   key_type :string, %i[secondary_key view_sql]
      #   key_type :string_or_array, %i[uniqueness_fields]
      #   key_type :hash, %i[batch_trigger], allowed_keys: %i[frequency run_at limit]
      #
      # Supported type symbols: +:boolean+, +:string+, +:string_or_array+, +:integer+, +:hash+
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
      #
      # +validate_key_types+ checks top-level hash_configuration keys against
      # key_type declarations, reporting warnings for unrecognized keys and errors
      # for type mismatches.
      module PatternValidation
        extend ActiveSupport::Concern

        VALID_FIELDS_KEY = :_valid_fields
        # Stores the YAML-declared fields list separately so lenient mode can
        # distinguish library-injected defaults (not declared) from real fields.
        DECLARED_FIELDS_KEY = :_declared_fields

        # Type-checking lambdas for key_type and value_pattern key_types.
        KEY_TYPE_CHECKERS = {
          boolean: ->(v) { [true, false].include?(v) },
          # Tri-state used by reference entries: accepts true/false or the
          # special string literal 'outside_master'.
          boolean_or_outside_master: ->(v) { [true, false, 'outside_master', :outside_master].include?(v) },
          string: ->(v) { v.is_a?(String) || v.is_a?(Symbol) },
          # Accepts a literal string (including substitution strings like
          # '{{field_name}}') or a Hash form such as { this: { field: return_value } }
          # used by field_default-style lookups (e.g. active_value).
          string_or_hash: ->(v) { v.is_a?(String) || v.is_a?(Symbol) || v.is_a?(Hash) },
          string_or_array: lambda { |v|
            v.is_a?(String) || v.is_a?(Symbol) ||
              (v.is_a?(Array) && v.all? { |i| i.is_a?(String) || i.is_a?(Symbol) })
          },
          integer: ->(v) { v.is_a?(Integer) },
          hash: ->(v) { v.is_a?(Hash) }
        }.freeze

        # Human-readable descriptions for each type symbol.
        KEY_TYPE_DESCRIPTIONS = {
          boolean: 'true or false',
          boolean_or_outside_master: "true, false or 'outside_master'",
          string: 'a string',
          string_or_hash: 'a string (literal or {{substitution}}) or a Hash (e.g. { this: { field: return_value } })',
          string_or_array: 'a string or array of strings',
          integer: 'an integer',
          hash: 'a Hash'
        }.freeze

        included do
          class_attribute :_extra_keys, default: []
          class_attribute :_value_patterns, default: {}
          class_attribute :_key_type_rules, default: {}
          class_attribute :_lenient_field_key_names, default: false
        end

        class_methods do
          # Opt the class in to lenient field key name validation.
          # In lenient mode, field keys that are neither in the YAML-declared
          # +fields:+ array nor in the model's DB columns are silently skipped
          # rather than generating a warning. This is appropriate for display
          # configuration classes (e.g. CaptionBefore, FieldOptions) where
          # library +_default+ blocks legitimately inject config for fields
          # that exist in some models but not others.
          def lenient_field_key_names!
            self._lenient_field_key_names = true
          end

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
          # @param key_types [Hash{Symbol => Symbol}, nil] per-key type constraints (Hash patterns only)
          def value_pattern(name, description:, match:, allowed_keys: nil, required_keys: nil, key_types: nil)
            if key_types && allowed_keys
              mismatched = key_types.keys.map(&:to_sym) - allowed_keys.map(&:to_sym)
              if mismatched.any?
                raise ArgumentError,
                      "value_pattern :#{name} has key_types keys #{mismatched} not in allowed_keys"
              end
            end

            self._value_patterns = _value_patterns.merge(
              name => {
                description:,
                match:,
                allowed_keys: allowed_keys&.freeze,
                required_keys: required_keys&.freeze,
                key_types: key_types&.freeze
              }
            ).freeze
          end

          # Declare type constraints on top-level hash_configuration keys.
          # Allowed keys are derived automatically from all key_type declarations.
          # @param type [Symbol] type specifier (:boolean, :string, :string_or_array, :integer, :hash)
          # @param keys [Symbol, Array<Symbol>] key names to constrain
          # @param allowed_keys [Array<Symbol>, nil] valid sub-keys (for :hash type only)
          def key_type(type, keys, allowed_keys: nil)
            new_rules = {}
            Array(keys).each { |key| new_rules[key] = { type:, allowed_keys: allowed_keys&.freeze } }
            self._key_type_rules = _key_type_rules.merge(new_rules).freeze
          end

          # Allowed keys derived from all key_type declarations.
          # @return [Array<Symbol>]
          def key_type_allowed_keys
            _key_type_rules.keys
          end

          # Default prepare_config that injects _valid_fields from parent context.
          # Only injects when the class has registered validate_field_key_names,
          # avoiding pollution of non-field-keyed classes (ViewOptions, Filestore, etc.).
          # Subclasses with custom prepare_config should call super or inject _valid_fields.
          # The _valid_fields set is enriched with the underlying model's real database
          # columns (where available) so that audit/FK columns such as
          # created_by_user_id, master_id and direct table FK references are
          # accepted even when not declared in the YAML `fields:` array.
          # @param raw [Hash, nil] raw config hash
          # @param parent [ExtraOptions] parent options instance
          # @return [Object] raw config with _valid_fields metadata
          def prepare_config(raw, parent)
            return raw unless raw.is_a?(Hash)
            return raw unless uses_field_key_validation?

            raw[VALID_FIELDS_KEY] = build_valid_fields(parent)
            raw[DECLARED_FIELDS_KEY] = Array(parent.fields).map(&:to_s) if _lenient_field_key_names
            raw
          end

          # Build the merged list of valid field names for key validation.
          # Combines the YAML-declared `fields:` array with the implementation
          # model's real attribute names (audit columns, foreign keys, etc.)
          # so legitimately existing columns aren't flagged as invalid.
          # @param parent [ExtraOptions]
          # @return [Array<String>]
          def build_valid_fields(parent)
            declared = Array(parent.fields).map(&:to_s)
            model_cols =
              begin
                co = parent.config_obj
                if co.respond_to?(:model_class) && co.model_class
                  co.model_class.attribute_names.map(&:to_s)
                else
                  []
                end
              rescue StandardError
                []
              end
            (declared + model_cols).uniq
          end

          # Whether this class has registered validate_field_key_names in its callbacks.
          # @return [Boolean]
          def uses_field_key_validation?
            _validate_callbacks.any? { |cb| cb.filter == :validate_field_key_names }
          end
        end

        # Globally-allowed field name patterns. These match framework-injected
        # columns, foreign-key columns and audit columns that legitimately
        # exist on dynamic-definition tables even when not enumerated in the
        # YAML `fields:` array. Patterns are applied in addition to the
        # per-class +extra_keys+ declarations.
        GLOBAL_FIELD_NAME_ALLOW_PATTERNS = [
          /_id\z/,                  # any foreign-key or audit *_id column
          /\Acreated_by_/,          # created_by_user_id, created_by_*
          /\Aupdated_by_/,          # updated_by_user_id, updated_by_*
          /\Aplaceholder_/,         # template/UI placeholder fields
          /\Aembedded_report_/,     # embedded report references
          /\Areference_/,           # related-record reference fields
          /\Aq\d+_/,                # framework status cols (q1_status, q2_*, ...)
          :form_version,
          :form_type,
          :form_status,
          :master_id,
          :user_id,
          :extra_log_type
        ].freeze

        # Check whether a field key matches any declared extra_keys entry,
        # falling back to the global allow patterns for framework / audit /
        # foreign-key columns.
        # @param field_name [Symbol] the key to check
        # @return [Boolean]
        def extra_key?(field_name)
          matchers = self.class._extra_keys + GLOBAL_FIELD_NAME_ALLOW_PATTERNS
          matchers.any? do |key|
            key.is_a?(Regexp) ? key.match?(field_name.to_s) : key.to_sym == field_name.to_sym
          end
        end

        # Validate all entry keys against valid field names and extra_keys.
        # Skips validation when _valid_fields metadata is not present.
        # Reports unrecognized keys as warnings.
        # In lenient mode (_lenient_field_key_names), a key that is not in
        # valid_fields is only flagged if it also appears in the model's
        # declared fields list. Keys introduced solely by library +_default+
        # blocks for fields absent from this model are silently ignored.
        def validate_field_key_names
          return unless hash_configuration.is_a?(Hash)

          valid_fields = hash_configuration[VALID_FIELDS_KEY]
          return unless valid_fields

          each_config_entry do |field_name, _value|
            next if extra_key?(field_name)
            next if valid_fields.include?(field_name.to_s)

            # Lenient mode: skip fields absent from both the declared fields list
            # and the model DB columns. These are library-provided defaults that
            # have no effect when the field doesn't exist in this model.
            if self.class._lenient_field_key_names
              declared = hash_configuration[DECLARED_FIELDS_KEY] || []
              next unless declared.include?(field_name.to_s)
            end

            extra_keys_desc = self.class._extra_keys.map { |k| k.is_a?(Regexp) ? k.inspect : k }.join(', ')
            add_validation_notice(field_name,
                                  "#{field_name} is not a valid field name" \
                                  "#{" or extra key (#{extra_keys_desc})" if extra_keys_desc.present?}",
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

        # Validate top-level hash_configuration keys against key_type declarations.
        # Warns about unrecognized keys and errors on type mismatches.
        def validate_key_types
          return unless hash_configuration.is_a?(Hash)
          return if self.class._key_type_rules.empty?

          allowed = self.class.key_type_allowed_keys
          hash_configuration.each_key do |key|
            next if key == VALID_FIELDS_KEY
            next if allowed.include?(key)

            failed_config(key, "unrecognized key '#{key}'", level: :warn)
          end

          self.class._key_type_rules.each do |key, rule|
            next unless hash_configuration.key?(key)

            value = hash_configuration[key]
            checker = KEY_TYPE_CHECKERS[rule[:type]]
            unless checker&.call(value)
              desc = KEY_TYPE_DESCRIPTIONS[rule[:type]] || rule[:type].to_s
              add_validation_notice(
                key,
                "#{key} must be #{desc}, current value: #{value.inspect} (#{value.class})"
              )
              next
            end

            # For hash-typed keys with allowed_keys, validate sub-keys
            next unless rule[:type] == :hash && rule[:allowed_keys]

            validate_allowed_hash_keys(key, value, rule[:allowed_keys])
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
            next if field_name == DECLARED_FIELDS_KEY

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

        # Apply constraints from a matched pattern (allowed_keys, required_keys, key_types).
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

          validate_pattern_key_types(field_name, value, pattern[:key_types]) if pattern[:key_types]

          return unless pattern[:required_keys]

          missing = pattern[:required_keys] - value.keys.map(&:to_sym)
          return if missing.empty?

          add_validation_notice(field_name,
                                "#{field_name} is missing required keys #{missing}")
        end

        # Check value types within a hash against key_types declarations.
        def validate_pattern_key_types(field_name, value, key_types)
          key_types.each do |kt_key, type|
            next unless value.key?(kt_key)

            checker = KEY_TYPE_CHECKERS[type]
            next if checker&.call(value[kt_key])

            desc = KEY_TYPE_DESCRIPTIONS[type] || type.to_s
            invalid_value = value[kt_key]
            add_validation_notice(
              field_name,
              "#{field_name} #{kt_key} must be #{desc}, current value: #{invalid_value.inspect} (#{invalid_value.class})"
            )
          end
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
