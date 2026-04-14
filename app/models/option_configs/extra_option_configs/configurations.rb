# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for top-level _configurations options.
    # Schema docs: docs/admin_reference/general/configurations.md
    # Extracted from ExtraOptions.parse_config
    #
    # Stores definition-level settings such as secondary_key, view_sql,
    # batch_trigger, prevent_migrations, etc. Values are stored in
    # the configurations hash keyed by setting name, supporting
    # Hash-like access via [], dig, reject, etc.
    class Configurations < BaseConfiguration
      # Known top-level configuration keys.
      # Values that are Hashes (e.g. batch_trigger) are stored as-is.
      RECOGNIZED_KEYS = %i[
        use_current_version secondary_key view_sql prevent_migrations
        batch_trigger tab_caption uniqueness_fields can_change_master
        foreign_key_through_external_id no_user_id default_option_type_name
        option_type_attr_name
      ].to_set.freeze

      BOOLEAN_KEYS = %i[
        use_current_version prevent_migrations can_change_master no_user_id
      ].to_set.freeze

      STRING_KEYS = %i[
        secondary_key view_sql tab_caption foreign_key_through_external_id
        option_type_attr_name default_option_type_name
      ].to_set.freeze

      BATCH_TRIGGER_KEYS = %i[frequency run_at limit if app_type user].to_set.freeze

      validate :validate_configurations_shape

      # Override to warn about unrecognized keys without requiring NamedConfiguration.
      def setup_named_configurations
        super
        return unless hash_configuration.is_a?(Hash)

        hash_configuration.each_key do |key|
          next if RECOGNIZED_KEYS.include?(key)

          failed_config(key, "unrecognized configuration key '#{key}'", level: :warn)
        end
      end

      # Hash-compatible reject returning a Hash (not Array).
      # Used by model_generator to filter existing configurations.
      def reject(&)
        configurations.reject(&)
      end

      private

      def validate_configurations_shape
        return unless hash_configuration.is_a?(Hash)

        validate_boolean_keys
        validate_string_keys
        validate_uniqueness_fields
        validate_batch_trigger
      end

      def validate_boolean_keys
        BOOLEAN_KEYS.each do |key|
          next unless hash_configuration.key?(key)
          next if [true, false].include?(hash_configuration[key])

          add_validation_notice(key, "#{key} must be true or false")
        end
      end

      def validate_string_keys
        STRING_KEYS.each do |key|
          next unless hash_configuration.key?(key)
          next if string_like?(hash_configuration[key])

          add_validation_notice(key, "#{key} must be a string")
        end
      end

      def validate_uniqueness_fields
        return unless hash_configuration.key?(:uniqueness_fields)

        value = hash_configuration[:uniqueness_fields]
        return if string_like?(value)
        return if value.is_a?(Array) && value.all? { |item| string_like?(item) }

        add_validation_notice(:uniqueness_fields, 'uniqueness_fields must be a string or array of strings')
      end

      def validate_batch_trigger
        return unless hash_configuration.key?(:batch_trigger)

        value = hash_configuration[:batch_trigger]
        unless value.is_a?(Hash)
          add_validation_notice(:batch_trigger, 'batch_trigger must be a Hash')
          return
        end

        validate_allowed_hash_keys(:batch_trigger, value, BATCH_TRIGGER_KEYS.to_a)
      end

      def string_like?(value)
        value.is_a?(String) || value.is_a?(Symbol)
      end
    end
  end
end
