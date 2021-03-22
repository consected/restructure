# frozen_string_literal: true

# Handle the loading of configuration definitions from YAML files in the directory
# app/models/admin/defs
module ConfigurationDefs
  extend ActiveSupport::Concern

  included do
    mattr_accessor :loaded_defs
  end

  class_methods do
    #
    # Load a definition file for a configuration type. Results are saved
    # within the `loaded_defs` class attribute to cache results
    # @param [Symbol] config_type
    # @return [Hash]
    def configuration_defs_for(config_type)
      self.loaded_defs ||= {}
      config_type = config_type.to_sym

      return loaded_defs[config_type] if loaded_defs[config_type]

      file_path = Rails.root.join('app', 'models', 'admin', 'defs', "#{config_type}_defs.yaml")
      raise FphsException, "Configuration Def type #{config_type} does not exist" unless File.exist?(file_path)

      content = File.read(file_path)
      loaded_defs[config_type] = YAML.safe_load(content)
    end
  end
end
