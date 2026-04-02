# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for database column configs.
    # Extracted from ExtraOptions#clean_db_configs_def
    #
    # Values are column configuration hashes keyed by column name.
    # The mutation of config_obj.db_columns is handled by ExtraOptions
    # after this config class runs.
    class DbConfigs < BaseConfiguration
      # No special processing needed — keys are already symbolized
      # by parse_options_text's deep_symbolize_keys!
    end
  end
end
