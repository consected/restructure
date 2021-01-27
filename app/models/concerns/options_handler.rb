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
##
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
    def option_types
      @option_types ||= []
    end

    def add_option_type(opt)
      option_types << opt
      attr_accessor(opt)
    end

    def option_types_simple
      @option_types_simple ||= []
    end

    def add_option_type_simple(opt)
      option_types_simple << opt
      attr_accessor(opt)
    end

    def configure(cname, with:)
      raise FphsException, ':access_options not allowed as a configure item' if with.include? :access_options

      c = Class.new(OptionsHandler::Configuration)
      c.send(:attr_accessor, *with)
      const_set(cname.ns_camelize, c)
      add_option_type cname
    end

    def configure_attributes(cnames)
      raise FphsException, ':access_options not allowed as a configure item' if cnames.include? :access_options

      attr_accessor(*cnames)

      cnames.each { |cname| add_option_type_simple(cname) }
    end
  end

  def initialize(owner = nil, use_hash_config: nil)
    self.owner = owner || self
    self.use_hash_config = use_hash_config
    access_options
  end

  protected

  def access_options
    return unless persisted?

    unless use_hash_config
      self.use_hash_config = YAML.safe_load(options, [Date, Time], [], true) if options.present?
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
