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
      key_type :boolean, %i[use_current_version prevent_migrations can_change_master no_user_id]
      key_type :string, %i[secondary_key view_sql tab_caption foreign_key_through_external_id
                           option_type_attr_name default_option_type_name]
      key_type :string_or_array, %i[uniqueness_fields]
      key_type :hash, %i[batch_trigger], allowed_keys: %i[frequency run_at limit if app_type user]

      validate :validate_key_types

      # Hash-compatible reject returning a Hash (not Array).
      # Used by model_generator to filter existing configurations.
      def reject(&)
        configurations.reject(&)
      end
    end
  end
end
