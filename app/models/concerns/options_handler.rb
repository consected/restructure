# frozen_string_literal: true

# Support structured options definitions for a class
# Simply call `configure` with a symbol naming the category of configuration
# and an array of symbols for each configuration attribute within this category.
#
# The configuration will be loaded from the #options attribute immediately after initialization of
# the class that includes this module.
# NOTE: remember to call `super` if you define #initialize in the parent class, to ensure
# loading happens.
#
# For example:
#      configure :view_css, with: %i[classes selectors]
# allows for configurations like:
#   view_css:
#     classes:
#       class-name:
#         display: block
#         margin-right: 20px
#     selectors:
#       "#an-id .some-class":
#         display: block
#
# If required, multiple named configurations can be used, each containing configurations.
# For example, if you want to add similar configurations under different names, for example
# defining named reports search attributes configurations, add the following
# to the configuration class:
#
#     class NamedConfiguration < OptionConfigs::BaseNamedConfiguration
#       configure <config_item>, with: %i[<child configs attributes>]
#       configure <config_item>, with: %i[<child configs attributes>]
#       configure_attributes %i[<simple config items>]
#     end
#
#
module OptionsHandler
  extend ActiveSupport::Concern

  class Configuration
    def initialize(params)
      return unless params

      params.each { |key, value| send "#{key}=", value }
    end
  end

  included do
    validate :access_options
    attr_accessor :owner, :use_hash_config

    # If we are within an ActiveRecord model, after_initialize will setup the
    # configurations automatically after instantiation of the class by new
    # If used outside a model, it is necessary to ensure new is called explicitly
    # and that the #initialize method (if defined) calls `super`
    after_initialize :access_options if respond_to? :after_initialize
  end

  class_methods do
    #
    # Class method for specifying a configuration item having child options
    # This creates a class having an accessor attribute for every child option
    # which is instantiated and populated when the configuration is loaded
    # on initialization of the main model instance. The configuration instance
    # is stored to an accessor attribute in the main model.
    # A list of the config items is available from #option_types
    # @param [Symbol] config_item_name - the name of the configuration item
    # @param [Array{Symbol}] with - the child options this configuration item defines
    def configure(config_item_name, with:)
      raise FphsException, ':access_options not allowed as a configure item' if with.include? :access_options

      c = Class.new(OptionsHandler::Configuration)
      c.send(:attr_accessor, *with)
      const_set(config_item_name.ns_camelize, c)
      add_option_type config_item_name
    end

    #
    # Class method for specifying simple configuration items (without children), defined as a list
    # This creates an accessor attribute in the main model instance which is populated
    # when the configuration is loaded when the model is instantiated.
    # A list of the simple attributes is available from #option_types_simple
    # @param [Array{Symbol}] config_item_name - list of names of the config items
    def configure_attributes(config_item_names)
      if config_item_names.include? :access_options
        raise FphsException,
              ':access_options not allowed as a configure item'
      end

      attr_accessor(*config_item_names)

      config_item_names.each { |config_item_name| add_option_type_simple(config_item_name) }
    end

    #
    # List of configuration items having child options.
    # Each represents the name of an accessor attribute in this model
    # @return [Array{Symbol}]
    def option_types
      @option_types ||= []
    end

    #
    # List of simple configuration items
    # Each represents the name of an accessor attribute in this model
    # @return [Array{Symbol}]
    def option_types_simple
      @option_types_simple ||= []
    end

    private

    def add_option_type(opt)
      option_types << opt
      attr_accessor(opt)
    end

    def add_option_type_simple(opt)
      option_types_simple << opt
      attr_accessor(opt)
    end
  end

  #
  # Provide initialization that can handle configuration options being attached to
  # an ActiveRecord::Base subclass (a model that stores to the database) or
  # an OptionConfigs::BaseConfiguration subclass (a Configuration class embedded within a model)
  # @param [Hash | UserBase] owner_or_params - if a Hash is passed this is expected to be initialization
  #    params for a regular model, otherwise we expect this to be a UserBase model itself to be referred back to
  # @param [Nil | Hash] options - if a Hash, this is expected to have the following options:
  # @option [Hash] :use_hash_config - provide option configurations as a hash rather than requiring YAML parsing
  def initialize(owner_or_params = nil, options = nil)
    if owner_or_params.is_a? Hash
      options = owner_or_params
      owner = nil
    else
      owner = owner_or_params
    end

    if is_a? ActiveRecord::Base
      super(options)
    else
      super()
    end

    options ||= {}
    self.owner = owner || self
    self.use_hash_config = options[:use_hash_config]
    access_options
  end

  protected

  #
  # Setup the options defined by:
  # - configure
  # - configure_attributes
  # Set the #user_hash_config attribute if the #config_text is parsed, or
  # use #user_hash_config directly if it already set
  # @return [Hash] the parsed config_text (or #use_hash_config) structure
  def access_options
    return unless persisted?

    unless use_hash_config
      self.use_hash_config = YAML.safe_load(config_text, [Date, Time], [], true) if config_text.present?
      self.use_hash_config ||= {}
    end

    self.use_hash_config = self.use_hash_config.symbolize_keys

    self.class.option_types.each do |ot|
      option_type = ot.to_s
      ot_class = "#{self.class.name}::#{option_type.ns_camelize}".constantize
      config_val = use_hash_config[ot]
      send("#{option_type}=", ot_class.new(config_val))
    end

    self.class.option_types_simple.each do |ot|
      config_val = use_hash_config[ot]
      send("#{ot}=", config_val)
    end

    use_hash_config
  end
end
