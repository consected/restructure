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
      ].to_set.freeze

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
    end
  end
end
