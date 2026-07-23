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

      value_pattern :column_config,
                    description: 'Column configuration hash',
                    match: Hash,
                    key_types: { type: :string, array: :boolean, index: :boolean, encrypted: :boolean }

      validate :validate_value_patterns
    end
  end
end
