# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for filestore configuration.
    # Schema docs: docs/admin_reference/general/filestore_container.md
    # Converted from ConfigBase to BaseConfiguration pattern.
    # Stores the entire hash as a single direct attribute.
    #
    # @example
    #   fs = Filestore.new(container: { path: '/data' })
    #   fs.filestore #=> { container: { path: '/data' } }
    class Filestore < BaseConfiguration
      configure_direct :filestore, type: :hash

      # Store the entire input hash as the filestore attribute
      # and populate configurations for hash-like [] access.
      # @return [void]
      def setup_named_configurations
        self.filestore = hash_configuration.presence || {}
        filestore.each { |k, v| configurations[k] = v }
      end
    end
  end
end
