# Support structured options definitions for a class
# Currently not widely used
# In the future we could look at combining this with ExtraOptions
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
    after_initialize :access_options
  end

  class_methods do
    def option_types
      @option_types
    end

    def add_option_type opt
      @option_types ||= []
      @option_types << opt
      attr_accessor(opt)
    end

    def configure cname, with:
      c = Class.new(OptionsHandler::Configuration)
      c.send(:attr_accessor, *with)
      const_set(cname.ns_camelize, c)
      add_option_type cname
    end
  end

  protected

  def access_options
    begin
      return unless id

      o = YAML.load options if options.present?
      o ||= {}

      self.class.option_types.each do |ot|
        option_type = ot.to_s
        ot_class = "#{self.class.name}::#{option_type.ns_camelize}".constantize
        c = o[option_type]
        send("#{option_type}=", ot_class.new(c))
      end
    end
    o
  end
end
