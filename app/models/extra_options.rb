class ExtraOptions

  def self.base_key_attributes
    [:name, :config_obj, :caption_before, :show_if, :resource_name, :save_action, :view_options, :field_options, :dialog_before, :creatable_if]
  end
  def self.add_key_attributes
    []
  end
  def self.key_attributes
    self.base_key_attributes + self.add_key_attributes
  end
  def self.editable_attributes
    self.key_attributes - [:name, :config_obj, :resource_name] + [:label]
  end

  attr_accessor *self.key_attributes


  def self.attr_defs
    {
      caption_before: {
        field_name: "string caption to appear before field",
        all_fields: "caption to appear before all fields",
        submit: "caption to appear before submit button"
      },
      show_if: {
        field_name: {
          depends_on_field_name: 'conditional value'
        }
      },
      view_options: {
        option_name: 'a value'
      },
      save_action: {
        label: 'button label'
      },
      field_options: {
        include_blank: 'true or false to force a drop down field to include a selectable blank'
      },
      dialog_before: {
        field_name: {name: "message template name", label: "show dialog button label" },
        all_fields: {name: "message template name", label: "show dialog button label" },
        submit: {name: "message template name", label: "show dialog button label" }
      },
      creatable_if: {
        all: {
          field_name: 'conditional value',
          field_name_2: 'AND conditional value'
        },
        not_any: {
          field_name: 'not conditional value',
          field_name_2: 'AND not conditional value'
        }
      }
    }
  end


  def initialize name, config, config_obj
    @name = name

    @config_obj = config_obj
    config.each do |k, v|
      begin
        self.send("#{k}=", v)
      rescue NoMethodError => e
        raise FphsException.new "Prevented a bad configuration of #{self.class.name} in #{config_obj.class.name} (#{config_obj.respond_to?(:human_name) ? config_obj.human_name : config_obj.id}). #{k} is not recognized as a valid attribute."
      end
    end

    self.resource_name = "#{config_obj.full_implementation_class_name.ns_underscore}__#{self.name.underscore}"
    self.caption_before ||= {}
    self.caption_before = self.caption_before.symbolize_keys

    self.dialog_before ||= {}
    self.dialog_before = self.dialog_before.symbolize_keys

    self.show_if ||= {}
    self.show_if = self.show_if.symbolize_keys

    self.save_action ||= {}
    self.save_action = self.save_action.symbolize_keys

    self.view_options ||= {}
    self.view_options = self.view_options.symbolize_keys

    self.field_options ||= {}
    self.field_options = self.field_options.symbolize_keys

    self.creatable_if ||= {}
    self.creatable_if = self.creatable_if.symbolize_keys


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
