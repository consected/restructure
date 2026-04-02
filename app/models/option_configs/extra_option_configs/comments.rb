# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for top-level _comments options.
    # Extracted from ExtraOptions.parse_config
    #
    # Stores table and field comments for the underlying database.
    # Keys: :table (string), :fields (hash of field_name => comment),
    # :original_fields (computed backup by handle_table_comments).
    class Comments < BaseConfiguration
      RECOGNIZED_KEYS = %i[table fields original_fields].to_set.freeze

      # Override to warn about unrecognized keys.
      def setup_named_configurations
        super
        return unless hash_configuration.is_a?(Hash)

        hash_configuration.each_key do |key|
          next if RECOGNIZED_KEYS.include?(key)

          failed_config(key, "unrecognized comment key '#{key}'", level: :warn)
        end
      end
    end
  end
end
