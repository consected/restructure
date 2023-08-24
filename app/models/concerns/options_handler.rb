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
  include ActiveModel::Validations

  class Configuration
    def initialize(params)
      return unless params

      params = params.symbolize_keys

      unrecognized = params.keys - self.class.configure_with_items
      # Allow a nil entry, to enable cleanup of previously allowed items
      unrecognized.delete_if { |u| params[u].nil? }
      if unrecognized.present?
        raise FphsException,
              "Unrecognized configuration params in #{self.class.name}: #{unrecognized.join(', ')}"
      end

      init_with(params)
    end

    def to_h
      res = {}
      self.class.configure_with_items.each { |k| res[k] = send(k) }
      res
    end

    alias to_hash to_h

    def filtered_hash
      to_h.filter { |_k, v| !v.nil? }
    end

    def init_with(params)
      params ||= {}
      self.class.configure_with_items.each { |key| send "#{key}=", params[key] }
    end

    def key?(key)
      to_h.key? key
    end
  end

  class ConfigurationHash < Hash
  end

  included do
    attr_accessor :owner, :orig_config_text
    attr_writer :hash_configuration

    # If we are within an ActiveRecord model, after_initialize will setup the
    # configurations automatically after instantiation of the class by new
    # If used outside a model, it is necessary to ensure new is called explicitly
    # and that the #initialize method (if defined) calls `super`
    after_initialize :setup_options if respond_to? :after_initialize

    before_validation :update_options if respond_to? :before_validation
    validate :save_options
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
    def configure(config_item_name, with:, is_child_of: nil)
      if with.include? :setup_from_hash_config
        raise FphsException, ':setup_from_hash_config not allowed as a configure item'
      end

      c = Class.new(OptionsHandler::Configuration)
      c.send(:attr_accessor, *with)
      c.send(:mattr_accessor, :configure_with_items)
      c.configure_with_items = with
      const_set(config_item_name.ns_camelize, c)

      add_option_type :multi, config_item_name, is_child_of
    end

    #
    # Class method for specifying simple configuration items (without children), defined as a list
    # This creates an accessor attribute in the main model instance which is populated
    # when the configuration is loaded when the model is instantiated.
    # A list of the simple attributes is available from #option_types_simple
    # Allow config_item_names to be specified as an array of symbols or as individual args
    # @param [Array{Symbol}] config_item_name - list of names of the config items
    def configure_attributes(*config_item_names)
      if config_item_names.length == 1 && config_item_names.first.is_a?(Array)
        config_item_names = config_item_names.first
      end

      overlay_methods = config_item_names & instance_methods
      raise FphsException, "#{overlay_methods} not allowed as a configure item" if overlay_methods.present?

      attr_accessor(*config_item_names)

      config_item_names.each { |config_item_name| add_option_type(:simple, config_item_name) }
    end

    #
    # Class method for specifying a hash of configuration items
    # This creates an accessor attribute in the main model instance which is populated
    # when the configuration is loaded when the model is instantiated.
    # A list of the simple attributes is available from #option_types_simple
    # Allow config_item_names to be specified as an array of symbols or as individual args
    #
    # The hash can be initialized like this:
    # f = {
    #   fields: {
    #     f1: {...},
    #     f2: {...}
    #   },
    #   ...
    # }
    # setup_options_hash(f, :fields)
    # It produces a class within the current class ...::Fields::Fields
    #
    # @param [Symbol] config_item_name - the name of the configuration item
    # @param [Array{Symbol}] with - the child options this configuration item defines
    def configure_hash(config_item_name, with:)
      attr_accessor(config_item_name)

      add_option_type(:hash, config_item_name)

      ch = Class.new(OptionsHandler::ConfigurationHash)
      const_set(config_item_name.ns_camelize, ch)

      c = Class.new(OptionsHandler::Configuration)
      c.send(:attr_accessor, *with)
      c.send(:mattr_accessor, :configure_with_items)
      c.configure_with_items = with
      ch.const_set(config_item_name.ns_camelize, c)
    end

    #
    # List of configuration items having child options.
    # Each represents the name of an accessor attribute in this model
    # @return [Array{Symbol}]
    def option_types
      @option_types ||= {
        multi: [],
        simple: [],
        hash: []
      }
    end

    #
    # The dynamic class for a configured option type
    def class_for(option_type, type: nil)
      option_type = "#{option_type}__#{option_type}" if type == :hash_item
      "#{name}::#{option_type.to_s.ns_camelize}".constantize
    end

    private

    def add_option_type(type, opt, parent = nil)
      parent ||= self
      option_types[type] << opt

      # raise FphsException, "#{opt} not allowed as an option type" if instance_methods.include? opt

      parent.attr_accessor(opt)
    end
  end

  #
  # Provide initialization that can handle configuration options being attached to
  # an ActiveRecord::Base subclass (a model that stores to the database) or
  # an OptionConfigs::BaseConfiguration subclass (a Configuration class embedded within a model)
  # @param [Hash | UserBase] owner_or_params - if a Hash is passed this is expected to be initialization
  #    params for a regular model, otherwise we expect this to be a UserBase model itself to be referred back to
  # @param [Nil | Hash] options - if a Hash, this is expected to have the following options:
  # @option [Hash] :hash_configuration - provide option configurations as a hash rather than requiring YAML parsing
  def initialize(owner_or_params = nil, options = nil)
    if owner_or_params.is_a?(Hash) ||
       owner_or_params.is_a?(ActionController::Parameters)
      options = owner_or_params
      owner = nil
      use_hash_config = options.delete :use_hash_config
    elsif options.is_a? Hash
      use_hash_config = options.delete :use_hash_config
      owner = owner_or_params
    else
      owner = owner_or_params
    end

    if is_a? ActiveRecord::Base
      super(options)
    else
      super()
    end

    self.owner = owner || self
    self.hash_configuration = use_hash_config

    parse_config_text unless hash_configuration

    setup_from_hash_config

    save_options if config_text.blank? && hash_configuration&.present?
  end

  #
  # Parse the YAML (or JSON) config text definition, stored in #config_text
  # and return a Hash with the definition
  def hash_configuration
    return @hash_configuration if @hash_configuration

    @hash_configuration = setup_options
  end

  #
  # Get the current hash_configuration, prepare a YAML document and
  # save to the options config_text attribute
  def save_options
    self.config_text = config_hash_to_yaml
  end

  #
  # Force a reload from the configuration text if it has changed since we loaded
  def update_options
    setup_options if config_text != orig_config_text
  end

  protected

  def setup_options
    self.orig_config_text ||= config_text
    parse_config_text
    setup_from_hash_config
  end

  def parse_config_text
    self.hash_configuration = {}

    return if config_text.blank?

    self.hash_configuration = JSON.parse config_text
  rescue StandardError
    self.hash_configuration = YAML.safe_load(config_text, [Date, Time], [], true)
  end

  #
  # The dynamic class for a configured option type
  def class_for(option_type, type: nil)
    self.class.class_for(option_type, type: type)
  end

  #
  # Setup the options defined by:
  # - configure
  # - configure_attributes
  # - configure_hash
  # Use #hash_configuration directly
  # @return [Hash]
  def setup_from_hash_config
    return {} unless hash_configuration.is_a? Hash

    self.hash_configuration = hash_configuration.symbolize_keys

    setup_all_options_multi hash_configuration
    setup_all_options_simple hash_configuration
    setup_all_options_hash hash_configuration

    hash_configuration
  end

  def setup_all_options_multi(hash_configuration)
    self.class.option_types[:multi].each do |option_type|
      ot_class = class_for(option_type)
      config_val = hash_configuration[option_type]
      send("#{option_type}=", ot_class.new(config_val))
    end
  end

  def setup_all_options_simple(hash_configuration)
    self.class.option_types[:simple].each do |option_type|
      config_val = hash_configuration[option_type]
      send("#{option_type}=", config_val)
    end
  end

  def setup_all_options_hash(hash_configuration)
    self.class.option_types[:hash].each do |option_type|
      setup_options_hash(hash_configuration, option_type)
    end
  end

  def setup_options_hash(hash_configuration, option_type)
    ot_hash_class = class_for(option_type)
    ot_class = class_for(option_type, type: :hash_item)
    config_val = hash_configuration[option_type]

    all_vals = ot_hash_class.new
    config_val&.each do |k, v|
      all_vals[k] = ot_class.new(v)
    end

    send("#{option_type}=", all_vals)
  end

  #
  # Take the current options and recreate a config hash based on the
  # current option settings
  # @return [Hash]
  def options_to_config_hash
    def_hash = {}

    self.class.option_types[:multi].each do |ot|
      obj = send(ot)
      obj.class.configure_with_items&.each do |i|
        def_hash[ot.to_s] ||= {}
        def_hash[ot.to_s][i] = obj.send(i)
      end
    end

    self.class.option_types[:simple].each do |ot|
      def_hash[ot.to_s] = send(ot)
    end

    self.class.option_types[:hash].each do |ot|
      obj_hash = send(ot)
      hash_class = class_for("#{ot}__#{ot}")
      d = def_hash[ot.to_s] = {}
      obj_hash&.each do |k, obj|
        hash_class.configure_with_items.each do |i|
          d[k.to_s] ||= {}
          d[k.to_s][i] = obj.send(i)
        end
      end
    end

    def_hash.deep_symbolize_keys
  end

  def config_hash_to_yaml
    config = options_to_config_hash
    YAML.dump(JSON.parse(config.to_json))
  end
end
