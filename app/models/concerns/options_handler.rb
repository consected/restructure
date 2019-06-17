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

    def add_option_type ot
      @option_types ||= []
      @option_types << ot
      attr_accessor(ot)
    end

    def option_types
      @option_types
    end

    def configure cname, with:
      c = Class.new(OptionsHandler::Configuration)
      c.send(:attr_accessor, *with)
      self.const_set(cname.ns_camelize, c)
      add_option_type cname
    end

  end


  protected

    def access_options

      begin
        return unless self.id
        o = YAML.load options if options.present?
        o ||= {}

        self.class.option_types.each do |ot|
          option_type = ot.to_s
          ot_class = "#{self.class.name}::#{option_type.ns_camelize}".constantize
          c = o[option_type]
          self.send("#{option_type}=", ot_class.new(c))
        end

      end
      return o
    end

end
