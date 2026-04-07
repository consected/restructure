# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for database column configs.
    # Schema docs: docs/admin_reference/general/db_columns.md
    # Extracted from ExtraOptions#clean_db_configs_def
    #
    # Values are column configuration hashes keyed by column name.
    # Each entry defines database column overrides (type, array, index, encrypted).
    # The mutation of config_obj.db_columns is handled by ExtraOptions
    # after this config class runs.
    class DbConfigs < BaseConfiguration
      # Named configuration for a single column's database settings.
      class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
        configure_attributes %i[type array index encrypted]
      end
    end
  end
end
