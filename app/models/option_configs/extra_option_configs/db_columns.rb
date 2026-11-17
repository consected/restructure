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
      ALLOWED_HASH_DIGEST_CLASSES = %w[sha1 sha256].freeze

      # Named configuration for a single column's database settings.
      class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
        configure_attributes %i[type array index encrypted hash_digest_class]
      end

      value_pattern :column_config,
                    description: 'Column configuration hash',
                    match: Hash,
                    key_types: { type: :string, array: :boolean, index: :boolean, encrypted: :boolean,
                                 hash_digest_class: :string }

      validate :validate_value_patterns
      validate :validate_hash_digest_class_values

      private

      def validate_hash_digest_class_values
        return unless hash_configuration.is_a?(Hash)

        each_config_entry do |field_name, value|
          next unless value.is_a?(Hash)

          digest = value[:hash_digest_class]
          next if digest.blank?

          next if ALLOWED_HASH_DIGEST_CLASSES.include?(digest.to_s.downcase)

          add_validation_notice(field_name,
                                "#{field_name} hash_digest_class '#{digest}' is unsupported. " \
                                "Allowed values: #{ALLOWED_HASH_DIGEST_CLASSES.join(', ')}")
        end
      end
    end
  end
end
