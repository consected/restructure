# frozen_string_literal: true

module OptionConfigs
  class BaseOptions
    include ActiveModel::Validations
    include OptionConfigs::ConfigErrors

    class << self
      # Build a machine-readable summary of accepted option configuration shapes.
      #
      # The returned hash is intended for documentation/export use and is derived
      # from runtime DSL metadata declared on:
      # - OptionConfigs::ExtraOptions config_class_registry entries
      # - OptionConfigs::TriggerTypes descriptors
      #
      # @param format [Symbol, String, nil] optional output format (:yaml or :json)
      # @return [Hash, String]
      def accepted_config_schema(format: nil)
        schema = {
          key_type_descriptions: key_type_descriptions,
          base_option_configs: base_option_configs_schema,
          trigger_types: trigger_types_schema
        }

        return schema if format.nil?

        serialize_config_schema(schema, format)
      end

      private

      def key_type_descriptions
        base_descriptions = OptionConfigs::ExtraOptionConfigs::Concerns::PatternValidation::KEY_TYPE_DESCRIPTIONS
        trigger_descriptions = OptionConfigs::TriggerTypes::Base::KEY_TYPE_DESCRIPTIONS

        base_descriptions.merge(trigger_descriptions).transform_keys(&:to_sym)
      end

      def serialize_config_schema(schema, format)
        case format.to_sym
        when :yaml
          String.yaml_dump(schema)
        when :json
          JSON.pretty_generate(schema)
        else
          raise ArgumentError, "Unsupported schema serialization format: #{format}. Use :yaml or :json"
        end
      end

      def base_option_configs_schema
        options_class = respond_to?(:config_class_registry) ? self : OptionConfigs::ExtraOptions
        options_class.config_class_registry.each_with_object({}) do |(registry_key, config_class), schema|
          schema[registry_key.to_sym] = summarize_base_option_config(config_class)
        end
      end

      def summarize_base_option_config(config_class)
        {
          class_name: config_class.name,
          kind: option_config_kind(config_class),
          source_attribute: reflected_value(config_class, :source_attribute),
          store_processed_value: reflected_value(config_class, :store_processed_value?),
          direct_types: reflected_hash(config_class, :direct_types),
          typed_attributes: reflected_hash(config_class, :typed_attribute_types) { |v| v.name },
          key_type_rules: key_type_rules_for(config_class),
          value_patterns: value_patterns_for(config_class),
          named_configuration_keys: named_configuration_keys_for(config_class)
        }.compact
      end

      def trigger_types_schema
        OptionConfigs::TriggerTypes::Base.registered_types.sort_by { |trigger_name, _klass| trigger_name.to_s }
                                         .each_with_object({}) do |(trigger_name, trigger_class), schema|
          schema[trigger_name.to_sym] = summarize_trigger_type(trigger_class)
        end
      end

      def summarize_trigger_type(trigger_class)
        {
          class_name: trigger_class.name,
          pattern: trigger_class.pattern,
          allowed_keys: Array(trigger_class.allowed_keys).map(&:to_sym),
          key_type_rules: trigger_key_type_rules_for(trigger_class)
        }
      end

      def trigger_key_type_rules_for(trigger_class)
        trigger_class.key_type_rules.each_with_object({}) do |(key, type), rules|
          rules[key.to_sym] = {
            type: type.to_sym,
            description: OptionConfigs::TriggerTypes::Base::KEY_TYPE_DESCRIPTIONS[type.to_sym]
          }
        end
      end

      def key_type_rules_for(config_class)
        return {} unless config_class.respond_to?(:_key_type_rules)

        config_class._key_type_rules.each_with_object({}) do |(key, rule), rules|
          type = rule[:type]&.to_sym
          rules[key.to_sym] = {
            type:,
            description: OptionConfigs::ExtraOptionConfigs::Concerns::PatternValidation::KEY_TYPE_DESCRIPTIONS[type],
            allowed_keys: Array(rule[:allowed_keys]).map(&:to_sym)
          }.compact
        end
      end

      def value_patterns_for(config_class)
        return {} unless config_class.respond_to?(:_value_patterns)

        config_class._value_patterns.each_with_object({}) do |(name, pattern), patterns|
          patterns[name.to_sym] = {
            description: pattern[:description],
            match: describe_match_spec(pattern[:match]),
            allowed_keys: Array(pattern[:allowed_keys]).map(&:to_sym),
            required_keys: Array(pattern[:required_keys]).map(&:to_sym),
            key_types: normalize_key_types(pattern[:key_types])
          }.compact
        end
      end

      def normalize_key_types(key_types)
        return {} unless key_types

        key_types.each_with_object({}) do |(key, type), normalized|
          sym_type = type.to_sym
          normalized[key.to_sym] = {
            type: sym_type,
            description: OptionConfigs::ExtraOptionConfigs::Concerns::PatternValidation::KEY_TYPE_DESCRIPTIONS[sym_type]
          }
        end
      end

      def named_configuration_keys_for(config_class)
        return [] unless config_class.const_defined?(:NamedConfiguration)

        named_configuration = config_class.const_get(:NamedConfiguration)
        return [] unless named_configuration.respond_to?(:option_types)

        Array(named_configuration.option_types[:simple]).map(&:to_sym)
      end

      def option_config_kind(config_class)
        if config_class < OptionConfigs::ExtraOptionConfigs::ConfigBase
          :config_base
        elsif config_class < OptionConfigs::ExtraOptionConfigs::BaseConfiguration
          :base_configuration
        else
          :other
        end
      end

      def reflected_value(config_class, method_name)
        return unless config_class.respond_to?(method_name)

        config_class.public_send(method_name)
      end

      def reflected_hash(config_class, method_name)
        return {} unless config_class.respond_to?(method_name)

        value = config_class.public_send(method_name)
        return {} unless value.is_a?(Hash)

        value.each_with_object({}) do |(k, v), normalized|
          normalized[k.to_sym] = block_given? ? yield(v) : v
        end
      end

      def describe_match_spec(match_spec)
        case match_spec
        when Class
          match_spec.name
        when Array
          match_spec.map { |m| m.is_a?(Class) ? m.name : m.to_s }
        when Proc
          'proc'
        else
          match_spec.to_s
        end
      end
    end

    # Get an array of ConfigLibrary objects from the options text
    def self.config_libraries(config_obj)
      c = config_obj.options_text.dup
      return [] unless c.present?

      format = config_obj.is_a?(Report) ? :sql : :yaml

      Admin::ConfigLibrary.make_substitutions! c, format
    end

    #
    # Read an admin defs file (yaml typically) and return the string content
    # @param [String | Array] filename
    # @return [String]
    def self.read_admin_defs(filename)
      filename = [filename] if filename.is_a? String

      raise FphsException, 'Paths including .. are not allowed' if filename.join('/').include?('..')

      path = %w[app models admin defs]
      path += filename
      File.read(Rails.root.join(*path))
    end
  end
end
