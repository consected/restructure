module OptionConfigs
  class BaseConfiguration < OptionConfigs::BaseOptions
    include OptionsHandler

    attr_accessor :errors, :configurations, :owner

    def initialize(owner)
      self.owner = owner
      self.errors = []
      self.configurations = {}

      super
      setup_named_configurations
    end

    #
    # A basic named configuration setup that can / should be
    # overridden to handle specific setup requirements
    # @return [<Type>] <description>
    def setup_named_configurations
      return unless defined? self.class::NamedConfiguration

      hash_configuration.each do |k, v|
        sym_key = k.to_sym
        add_named_configuration(sym_key, v)
      end
    end

    #
    # Add a named configuration to the set
    # @param [Symbol] sym_key - key name
    # @param [Object] value
    # @return [NamedConfiguration]
    def add_named_configuration(sym_key, value)
      configurations[sym_key] = self.class::NamedConfiguration.new self, use_hash_config: { sym_key => value }
    end

    #
    # Add a named configuration to a Hash attribute
    # @param [Symbol] name - configuration attribute name
    # @param [Symbol] sym_key - key name
    # @param [Object] value
    # @return [NamedConfiguration]
    def add_configuration(type, name, sym_key, value)
      configurations[name] ||= {}
      configurations[name][sym_key] = type.new(self, use_hash_config: { sym_key => value })
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
  end
end
