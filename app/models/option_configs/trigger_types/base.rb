# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Base class for per-trigger-type descriptor classes.
    # Provides DSL class methods for declaring structural pattern,
    # allowed configuration keys, and per-key type constraints.
    #
    # Subclasses register themselves automatically via +trigger_name+.
    # The registry is accessed via +Base.for(:trigger_name)+.
    #
    # @example Defining a trigger type
    #   class Notify < Base
    #     trigger_name :notify
    #     pattern :named_entry
    #     allowed_keys %i[type role subject if on_complete on_failure]
    #     key_type :string, :type
    #     key_type :boolean, :ignore_no_recipients
    #   end
    class Base
      BASE_KEY_TYPE_CHECKERS = OptionConfigs::ExtraOptionConfigs::Concerns::PatternValidation::KEY_TYPE_CHECKERS
      BASE_KEY_TYPE_DESCRIPTIONS = OptionConfigs::ExtraOptionConfigs::Concerns::PatternValidation::KEY_TYPE_DESCRIPTIONS

      KEY_TYPE_CHECKERS = BASE_KEY_TYPE_CHECKERS.merge(
        any: ->(_v) { true },
        array: ->(v) { v.is_a?(Array) },
        hash_or_array: ->(v) { v.is_a?(Hash) || v.is_a?(Array) },
        string_or_hash: ->(v) { v.is_a?(String) || v.is_a?(Symbol) || v.is_a?(Hash) },
        string_or_integer_or_hash: ->(v) { v.is_a?(String) || v.is_a?(Symbol) || v.is_a?(Integer) || v.is_a?(Hash) },
        scalar_or_array_or_hash: lambda { |v|
          v.is_a?(String) || v.is_a?(Symbol) || v.is_a?(Numeric) ||
            [true, false, nil].include?(v) || v.is_a?(Array) || v.is_a?(Hash)
        }
      ).freeze

      KEY_TYPE_DESCRIPTIONS = BASE_KEY_TYPE_DESCRIPTIONS.merge(
        any: 'any value',
        array: 'an Array',
        hash_or_array: 'a Hash or Array',
        string_or_hash: 'a string or Hash',
        string_or_integer_or_hash: 'a string, integer, or Hash',
        scalar_or_array_or_hash: 'a scalar, Array, or Hash'
      ).freeze

      class << self
        # Registry of trigger name → class mappings.
        # @return [Hash{Symbol => Class}]
        def registered_types
          load_trigger_type_classes
          @registered_types ||= {}
        end

        # Look up the descriptor class for a trigger name.
        # @param name [Symbol, String] trigger action name
        # @return [Class, nil]
        def for(name)
          registered_types[name.to_sym]
        end

        # DSL: register this class under a trigger name.
        # @param name [Symbol] trigger action name
        def trigger_name(name)
          @_trigger_name = name.to_sym
          Base.registered_types[@_trigger_name] = self
        end

        # DSL: declare the structural pattern.
        # @param value [Symbol, nil] :direct_config, :named_entry, or :delegate
        # @return [Symbol]
        def pattern(value = nil)
          if value
            @_pattern = value
          else
            @_pattern
          end
        end

        # DSL: declare the allowed configuration keys.
        # @param keys [Array<Symbol>, nil] the valid keys
        # @return [Array<Symbol>, nil]
        def allowed_keys(keys = nil)
          if keys
            @_allowed_keys = keys.freeze
          else
            @_allowed_keys
          end
        end

        # DSL: declare per-key type constraints.
        # @param type_sym [Symbol] type specifier (:boolean, :string, :integer, etc.)
        # @param keys [Symbol, Array<Symbol>] key name(s) to constrain
        # @param allowed_keys [Array<Symbol>, nil] when the key's value is a Hash (or an
        #   Array of Hashes, e.g. change_user_roles' add_role_names), validates the inner
        #   hash(es) do not contain unrecognized keys
        # @param key_types [Hash{Symbol => Symbol}, nil] per-inner-key type constraints,
        #   checked the same way as top-level key_type rules, for each Hash described above
        def key_type(type_sym, *keys, allowed_keys: nil, key_types: nil)
          @_key_type_rules ||= {}
          @_nested_key_rules ||= {}
          keys.flatten.each do |k|
            @_key_type_rules[k] = type_sym
            next unless allowed_keys || key_types

            @_nested_key_rules[k] = { allowed_keys: allowed_keys&.freeze, key_types: key_types&.freeze }.freeze
          end
        end

        # DSL helper: declare standard lifecycle hook key types used by save triggers.
        # @return [void]
        def standard_hook_key_types
          key_type :hash, :if
          key_type :hash_or_array, :on_complete, :on_failure
        end

        # Accessor for key type rules hash.
        # @return [Hash{Symbol => Symbol}]
        def key_type_rules
          @_key_type_rules || {}
        end

        # Accessor for nested key validation rules (allowed_keys:/key_types: passed to key_type).
        # @return [Hash{Symbol => Hash}]
        def nested_key_rules
          @_nested_key_rules || {}
        end

        # Validate a config hash (or array of config hashes) according to this
        # type's pattern and constraints.
        # Returns an array of warning message strings (empty if valid).
        # Array-valued trigger configs (e.g. +notify: [ {...}, {...} ]+) are
        # validated element-by-element.
        # @param config [Hash, Array, Object] the trigger's configuration
        # @return [Array<String>]
        def validate_config(config)
          return [] if @_pattern == :delegate

          return config.flat_map { |entry| validate_config(entry) } if config.is_a?(Array)

          return [] unless config.is_a?(Hash)

          case @_pattern
          when :direct_config
            validate_direct(config)
          when :named_entry
            validate_named_entries(config)
          else
            []
          end
        end

        private

        # Ensure all trigger type descriptor classes are loaded.
        # This guarantees registry lookups work regardless of spec/file load order.
        # @return [void]
        def load_trigger_type_classes
          return if defined?(@_trigger_type_classes_loaded) && @_trigger_type_classes_loaded

          Dir.glob(File.join(__dir__, '*.rb')).each do |file|
            next if File.basename(file) == 'base.rb'

            require_dependency file
          end

          @_trigger_type_classes_loaded = true
        end

        # Validate keys directly against allowed_keys and key_type_rules.
        # @param config [Hash] config hash
        # @return [Array<String>]
        def validate_direct(config)
          warnings = []
          warnings.concat(check_allowed_keys(config))
          warnings.concat(check_key_types(config))
          warnings
        end

        # Keys that appear at the outer level of named-entry configs as container
        # metadata rather than trigger-type-specific content.  Their presence must
        # NOT flip classification to direct form, because they are valid at both
        # levels (e.g. create_reference: { my_ref: {...}, on_complete: {...} }).
        NAMED_ENTRY_OUTER_KEYS = %i[if on_complete on_failure].freeze

        # Validate keys inside each named entry.
        # @param config [Hash] config hash with arbitrary entry names
        # @return [Array<String>]
        #
        # Auto-detects direct form when any outer key (excluding lifecycle hook
        # keys which are valid at both levels) is present in @_allowed_keys.
        # This handles trigger types whose runtime implementation accepts both a
        # direct hash and a named-entry hash.
        def validate_named_entries(config)
          non_lifecycle_keys = config.keys.map(&:to_sym) - NAMED_ENTRY_OUTER_KEYS
          return validate_direct(config) if @_allowed_keys && non_lifecycle_keys.any? { |k| @_allowed_keys.include?(k) }

          warnings = []
          config.each do |k, inner|
            # Skip lifecycle hook keys — their values are nested trigger task
            # lists, not inner named-entry config hashes.
            next if NAMED_ENTRY_OUTER_KEYS.include?(k.to_sym)
            next unless inner.is_a?(Hash)

            warnings.concat(check_allowed_keys(inner))
            warnings.concat(check_key_types(inner))
          end
          warnings
        end

        # Check for unrecognized keys.
        # @param hash [Hash] the config hash to check
        # @return [Array<String>]
        def check_allowed_keys(hash)
          return [] unless @_allowed_keys

          invalid = hash.keys.map(&:to_sym) - @_allowed_keys
          invalid.map { |k| "unrecognized key '#{k}'" }
        end

        # Check key type constraints.
        # @param hash [Hash] the config hash to check
        # @return [Array<String>]
        def check_key_types(hash)
          return [] if key_type_rules.empty?

          hash = hash.transform_keys(&:to_sym)

          warnings = []
          key_type_rules.each do |key, type_sym|
            next unless hash.key?(key)
            # Empty YAML keys (e.g. `extra_substitutions:`) parse as nil and are
            # semantically equivalent to the key being absent — skip type-checking.
            next if hash[key].nil?

            checker = KEY_TYPE_CHECKERS[type_sym]
            if checker&.call(hash[key])
              warnings.concat(check_nested_keys(key, hash[key]))
              next
            end

            desc = KEY_TYPE_DESCRIPTIONS[type_sym] || type_sym.to_s
            warnings << "#{key} must be #{desc}"
          end
          warnings
        end

        # Validate the inner keys of a nested Hash value (or each Hash within an
        # Array value, e.g. change_user_roles' add_role_names) against the
        # allowed_keys:/key_types: rules declared via +key_type+.
        # @param key [Symbol] the outer key being checked
        # @param value [Hash, Array, Object] the outer key's value
        # @return [Array<String>]
        def check_nested_keys(key, value)
          rules = nested_key_rules[key]
          return [] unless rules

          entries = value.is_a?(Array) ? value : [value]
          warnings = []

          entries.each do |entry|
            next unless entry.is_a?(Hash)

            entry = entry.transform_keys(&:to_sym)

            if rules[:allowed_keys]
              invalid = entry.keys - rules[:allowed_keys]
              warnings.concat(invalid.map { |k| "#{key}.#{k} unrecognized key" })
            end

            next unless rules[:key_types]

            rules[:key_types].each do |inner_key, inner_type|
              next unless entry.key?(inner_key)
              next if entry[inner_key].nil?

              inner_checker = KEY_TYPE_CHECKERS[inner_type]
              next if inner_checker&.call(entry[inner_key])

              desc = KEY_TYPE_DESCRIPTIONS[inner_type] || inner_type.to_s
              warnings << "#{key}.#{inner_key} must be #{desc}"
            end
          end
          warnings
        end
      end
    end
  end
end
