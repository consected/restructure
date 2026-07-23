# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for top-level _data_dictionary options.
    # Schema docs: docs/admin_reference/general/data_dictionary.md
    # Extracted from ExtraOptions.parse_config
    #
    # Stores data dictionary settings for automatic variable registration.
    # Consumed by Dynamic::DataDictionary to populate Datadic::Variable records.
    class DataDictionaryConfig < BaseConfiguration
      RECOGNIZED_KEYS = %i[
        study domain prevent_update source_name source_type form_name
        storage_type db_or_fs schema_or_path table_or_file is_derived_var
        owner_email fields derived_var_options
      ].to_set.freeze

      # Override to warn about unrecognized keys.
      def setup_named_configurations
        super
        return unless hash_configuration.is_a?(Hash)

        hash_configuration.each_key do |key|
          next if RECOGNIZED_KEYS.include?(key)

          failed_config(key, "unrecognized data dictionary key '#{key}'", level: :warn)
        end
      end
    end
  end
end
