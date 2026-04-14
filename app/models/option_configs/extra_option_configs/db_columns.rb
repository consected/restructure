# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for top-level _db_columns options.
    # Schema docs: docs/admin_reference/general/db_columns.md
    # Extracted from ExtraOptions.parse_config
    #
    # Stores database column overrides keyed by field name.
    # Each entry defines the column type, array flag, index flag,
    # and encryption flag. Values are stored as NamedConfiguration
    # instances supporting Hash-like access via [], dig, select, etc.
    class DbColumns < BaseConfiguration
      # Named configuration for a single column's database settings.
      class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
        configure_attributes %i[type array index encrypted]
      end

      COLUMN_TYPE_VALUES = %w[string datetime date integer float decimal bigint].to_set.freeze

      BOOLEAN_KEYS = %i[array index encrypted].to_set.freeze

      validate :validate_db_columns_shape

      private

      def validate_db_columns_shape
        return unless hash_configuration.is_a?(Hash)

        hash_configuration.each do |field_name, config|
          next unless config.is_a?(Hash)

          validate_column_type(field_name, config)
          validate_column_booleans(field_name, config)
        end
      end

      def validate_column_type(field_name, config)
        return unless config.key?(:type)
        return if config[:type].is_a?(String) || config[:type].is_a?(Symbol)

        add_validation_notice(field_name, "#{field_name} type must be a string")
      end

      def validate_column_booleans(field_name, config)
        BOOLEAN_KEYS.each do |key|
          next unless config.key?(key)
          next if [true, false].include?(config[key])

          add_validation_notice(field_name, "#{field_name} #{key} must be true or false")
        end
      end
    end
  end
end
