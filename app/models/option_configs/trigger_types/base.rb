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
        def key_type(type_sym, *keys)
          @_key_type_rules ||= {}
          keys.flatten.each { |k| @_key_type_rules[k] = type_sym }
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

        # Validate a config hash according to this type's pattern and constraints.
        # Returns an array of warning message strings (empty if valid).
        # @param config [Hash] the trigger's configuration
        # @return [Array<String>]
        def validate_config(config)
          return [] unless config.is_a?(Hash)
          return [] if @_pattern == :delegate

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

        # Validate keys inside each named entry.
        # @param config [Hash] config hash with arbitrary entry names
        # @return [Array<String>]
        def validate_named_entries(config)
          warnings = []
          config.each_value do |inner|
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

            checker = KEY_TYPE_CHECKERS[type_sym]
            next if checker&.call(hash[key])

            desc = KEY_TYPE_DESCRIPTIONS[type_sym] || type_sym.to_s
            warnings << "#{key} must be #{desc}"
          end
          warnings
        end
      end
    end
  end
end
