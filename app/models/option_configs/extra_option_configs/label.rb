# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for the definition label.
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Stores the label string as a direct value.
    # Uses prepare_config to default to humanized name when not specified.
    # The processed string is stored back on the parent ExtraOptions (not the object).
    class Label < BaseConfiguration
      configure_direct :label, type: :string

      def self.store_processed_value?
        true
      end

      # Default the label to the humanized option name when not specified.
      # @param raw [String, nil] the raw label value from YAML config
      # @param parent [ExtraOptions] the parent ExtraOptions instance
      # @return [String] the label string
      def self.prepare_config(raw, parent)
        raw || parent.name.to_s.humanize
      end

      # Store the string value, defaulting to empty string.
      # Warns when label is not a string (e.g. a Hash was provided).
      # @return [void]
      def setup_named_configurations
        if hash_configuration.is_a?(String)
          self.label = hash_configuration
        else
          self.label = ''
          unless hash_configuration.blank?
            failed_config(:label, "label must be a string, got #{hash_configuration.class.name.downcase}", level: :warn)
          end
        end
      end
    end
  end
end
