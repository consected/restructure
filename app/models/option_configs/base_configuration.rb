module OptionConfigs
  class BaseConfiguration < OptionConfigs::BaseOptions
    include OptionsHandler

    attr_accessor :errors, :configurations

    def initialize(owner)
      self.owner = owner
      self.errors = []
      setup_named_configurations
      super
    end

    #
    # A basic named configuration setup that can / should be
    # overridden to handle specific setup requirements
    # @return [<Type>] <description>
    def setup_named_configurations
      return unless defined? NamedConfiguration

      self.configurations = {}
      hash_configuration.each do |k, v|
        sym_key = k.to_sym
        configurations[sym_key] = NamedConfiguration.new self, use_hash_config: { sym_key => v }
      end
    end

    #
    # Access a configuration by symbolized key name
    # @param [Symbol] key
    # @return [NamedConfiguration]
    def [](key)
      configurations[key]
    end

    #
    # Simple Hash iterator on the configuration
    def each(&block)
      configurations.each(&block)
    end

    #
    # Parse the YAML (or JSON) config text definition, stored in #config_text
    # and return a Hash with the definition
    def hash_configuration
      return @hash_configuration if @hash_configuration

      return @hash_configuration = {} if config_text.blank?

      begin
        @hash_configuration = JSON.parse config_text
      rescue StandardError
        @hash_configuration = YAML.safe_load(config_text, [], [], true)
      end
    end
  end
end
