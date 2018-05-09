class ExtraOptions

  attr_accessor :name, :config_obj, :caption_before, :show_if, :resource_name, :save_action, :view_options, :field_options, :dialog_before, :creatable_if, :editable_if

  def initialize name, config, config_obj
    @name = name

    @config_obj = config_obj
    config.each {|k, v| self.send("#{k}=", v)}

    self.resource_name = "#{config_obj.full_implementation_class_name.ns_underscore}__#{self.name.underscore}"
    self.caption_before ||= {}
    self.caption_before = self.caption_before.symbolize_keys

    self.show_if ||= {}
    self.show_if = self.show_if.symbolize_keys

    self.save_action ||= {}
    self.save_action = self.save_action.symbolize_keys

    self
  end

  def self.parse_config config_obj

    c = options_text(config_obj)

    configs = []
    begin
      if c.present?
        res = YAML.load(c)
      else
        res = {}
      end

      set_defaults config_obj, res

      res.each do |name, value|
        i = self.new name, value, config_obj
        configs << i
      end

    end

    return configs
  end

  protected

    def self.options_text config_obj
      config_obj.options
    end

    def self.set_defaults config_obj, all_options={}

    end

end
