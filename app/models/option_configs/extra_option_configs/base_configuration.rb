# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Base class for field-keyed configuration classes that follow the
    # BaseConfiguration/NamedConfiguration pattern.
    #
    # Inherits from OptionConfigs::BaseConfiguration and provides:
    # - Hash initialization: `ConfigClass.new({ field1: value1, field2: value2 })`
    # - Hash-like interface: `[]`, `[]=`, `merge!`, `keys`, `each`, `blank?`, `key?`
    # - Backward compatibility: `symbolize_keys`, `as_json`, `to_json`
    # - Error reporting: `failed_config` stores errors locally for ExtraOptions to collect
    #
    # Subclasses may:
    # - Define a NamedConfiguration inner class for structured field values
    # - Override `add_named_configuration` for preprocessing (call super with processed value)
    # - Define `self.prepare_config(raw, parent)` for pre-initialization context needs
    # - Override `self.store_processed_value?` to return true for classes that should
    #   store their processed attribute value on the parent ExtraOptions instead of the object
    class BaseConfiguration < OptionConfigs::BaseConfiguration
      include Enumerable

      # Provide a model_name that handles anonymous subclasses.
      # ActiveModel::Name requires a class name; anonymous classes have nil.
      # Falls back to 'Configuration' for anonymous classes.
      def self.model_name
        @_model_name ||= ActiveModel::Name.new(self, nil, name || 'Configuration')
      end

      # Whether the registry should store the processed attribute value (not the object)
      # on the parent ExtraOptions. Override to return true in subclasses that act as
      # value preprocessors (e.g. Label, Fields, *_if classes).
      # @return [Boolean]
      def self.store_processed_value?
        false
      end

      # Optional: override to read raw input from a different ExtraOptions attribute
      # than the registry key. For example, References uses `source_attribute :references`
      # so the registry key `references_config` reads its input from `extra_options.references`,
      # and the enriched hash is stored back there while the instance is kept at the registry key.
      # @return [Symbol, nil] the source attribute name, or nil to use the registry key
      def self.source_attribute
        nil
      end

      # Initialize with just a hash config (no owner required).
      # Bypasses the parent's owner-based initialization since these
      # config classes don't persist independently — managed by ExtraOptions.
      # @param [Hash, Array, nil] hash_config - raw configuration (usually a Hash keyed by field name,
      #   but may be an Array for classes like TriggerTasks that accept list values)
      def initialize(hash_config = {})
        self.errors = ActiveModel::Errors.new(self)
        self.config_errors = []
        self.config_warnings = []
        self.configurations = {}
        self.hash_configuration = hash_config.is_a?(Hash) ? hash_config.symbolize_keys : (hash_config || {})
        setup_named_configurations
        run_validations
      end

      # Default setup: iterate hash entries and create configurations.
      # Subclasses override for custom preprocessing.
      # @return [void]
      def setup_named_configurations
        hash_configuration.each do |k, v|
          add_named_configuration(k.to_sym, v)
        end
      end

      # Override parent's add_named_configuration to pass value directly
      # (not wrapped in {key => value}).
      # For classes with NamedConfiguration and Hash values, creates a NamedConfiguration.
      # For classes without (or with non-Hash values), stores the value directly.
      # @param [Symbol] sym_key - field name
      # @param [Object] value - field configuration value
      def add_named_configuration(sym_key, value)
        configurations[sym_key] = if self.class.const_defined?(:NamedConfiguration) && value.is_a?(Hash)
                                    nc = self.class::NamedConfiguration.new(self, use_hash_config: value)
                                    nc.validate_recognized_keys
                                    nc
                                  else
                                    value
                                  end
      end

      # Assign a field configuration by key.
      # @param [Symbol | String] key - field name
      # @param [Object] value - field configuration
      def []=(key, value)
        add_named_configuration(key.to_sym, value)
      end

      # Merge a plain hash of field configurations.
      # @param [Hash] other_hash - hash of { field_name: config } entries
      # @return [self]
      def merge!(other_hash)
        other_hash.each { |k, v| add_named_configuration(k.to_sym, v) }
        self
      end

      # Return symbol keys of all configured fields.
      # @return [Array<Symbol>]
      def keys
        configurations.keys
      end

      # Check if a field key exists.
      # @param [Symbol | String] key
      # @return [Boolean]
      def key?(key)
        configurations.key?(key.to_sym)
      end

      alias has_key? key?

      # Returns true when no fields are configured.
      def blank?
        configurations.blank?
      end

      # Returns true when no fields are configured (Hash-compatible).
      def empty?
        configurations.empty?
      end

      # Hash-compatible dig for nested access.
      # Delegates to configurations hash then chains dig on the result.
      # @param keys [Array<Symbol>] nested key path
      # @return [Object, nil]
      def dig(*keys)
        first = keys.shift
        val = configurations[first.to_sym]
        return val if keys.empty? || val.nil?

        val.respond_to?(:dig) ? val.dig(*keys) : nil
      end

      # Hash-compatible iteration methods delegated to configurations.
      delegate :each_value, :each_key, :each_pair, :values, :size, :length,
               :any?, :all?, :none?, :count, :to_a, :map, to: :configurations

      # Delegates to configurations hash for iteration.
      # Yields [key, value] pairs for iteration.
      # @yield [Symbol, Object] field name and its configuration value
      def each(&)
        configurations.each(&)
      end

      # Override Enumerable#select to preserve Hash return type,
      # matching the behavior of Hash#select/filter.
      # @return [Hash]
      def select(&)
        configurations.select(&)
      end

      alias filter select

      # Equality comparison: compare as plain Hash for backward compatibility
      # with code that previously compared against Hash literals.
      # @param other [Object] value to compare against
      # @return [Boolean]
      def ==(other)
        return symbolize_keys == other if other.is_a?(Hash)

        super
      end

      # Returns a plain Hash representation for backward compatibility.
      # NamedConfiguration values are converted to filtered hashes;
      # plain values are returned as-is.
      # @return [Hash{Symbol => Object}]
      def symbolize_keys
        configurations.transform_values do |v|
          v.respond_to?(:filtered_hash) ? v.filtered_hash : v
        end
      end

      # JSON serialization producing the same format as the original plain hash.
      # @return [Hash]
      def as_json(options = nil)
        symbolize_keys.as_json(options)
      end

      def to_json(*)
        as_json.to_json(*)
      end

      # OptionsHandler persistence stubs — field-keyed configs don't store YAML independently
      def config_text = nil

      def config_text=(value); end

      def save_options; end

      def persisted? = false

      protected

      # Error reporting — stores errors locally.
      # ExtraOptions collects these after initialization.
      # @param [Symbol] type - error category
      # @param [String] message - error description
      # @param [Object] extra_details - additional context
      # @param [Symbol] level - :error or :warn
      def failed_config(type, message, extra_details: nil, level: :error)
        target = (level == :warn ? config_warnings : config_errors)
        target << { type:, message:, extra_details: }
      end

      private

      # Bridge ActiveModel::Validations errors into config_errors.
      # Called at the end of initialize so that subclass validates
      # declarations are checked after setup_named_configurations.
      # Errors with options[:type] == :warning are directed to config_warnings.
      def run_validations
        return if valid?

        errors.each do |error|
          level = error.options[:type] == :warning ? :warn : :error
          failed_config error.attribute, "#{error.attribute} #{error.message}", level: level
        end
      end
    end
  end
end
