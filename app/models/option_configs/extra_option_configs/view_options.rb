# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for view options.
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Stores the entire hash as a single direct attribute.
    #
    # @example
    #   vo = ViewOptions.new(data_attribute: 'field_1', show_embedded: true)
    #   vo.view_options #=> { data_attribute: 'field_1', show_embedded: true }
    class ViewOptions < BaseConfiguration
      configure_direct :view_options, type: :hash

      # Store the entire input hash as the view_options attribute
      # and populate configurations for hash-like [] access.
      # @return [void]
      def setup_named_configurations
        self.view_options = hash_configuration.presence || {}
        view_options.each { |k, v| configurations[k] = v }
      end
    end
  end
end
