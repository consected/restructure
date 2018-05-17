class ExtraOptions

  def self.base_key_attributes
    [:name, :config_obj, :caption_before, :show_if, :resource_name, :save_action, :view_options, :field_options, :dialog_before, :creatable_if, :editable_if]
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

  attr_accessor(*self.key_attributes)


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
        show_embedded_at_top: 'true | false to position a single auto loaded embedded item',
        hide_unless_creatable: 'true | false to hide add-item buttons in activity logs if they are not creatable'
      },
      save_action: {
        label: 'button label'
      },
      field_options: {
        field_name: {
          include_blank: 'true or false to force a drop down field to include a selectable blank'
        }
      },
      dialog_before: {
        field_name: {name: "message template name", label: "show dialog button label" },
        all_fields: {name: "message template name", label: "show dialog button label" },
        submit: {name: "message template name", label: "show dialog button label" }
      },
      creatable_if: attr_for_conditions,
      editable_if: attr_for_conditions
    }
  end

  def self.attr_for_conditions
    {

      all: {
        model_table_name: {
          field_name: 'all conditional values must be true',
          field_name_2: '...'
        }
      },
      any: {
        model_table_name: {
          field_name: 'any conditional value must be true',
          field_name_2: '...'
        }
      },
      not_any: {
        model_table_name: {
          field_name: 'all conditional values must be false',
          field_name_2: '...'
        }
      },
      not_all: {
        model_table_name: {
          field_name: 'any conditional value must be false',
          field_name_2: '...'
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
      rescue NoMethodError
        raise FphsException.new "Prevented a bad configuration of #{self.class.name} in #{config_obj.class.name} (#{config_obj.respond_to?(:human_name) ? config_obj.human_name : config_obj.id}). #{k} is not recognized as a valid attribute."
      end
    end

    self.resource_name = "#{config_obj.full_implementation_class_name.ns_underscore}__#{self.name.underscore}"
    self.caption_before ||= {}
    self.caption_before = self.caption_before.symbolize_keys
    self.caption_before = self.caption_before.each {|k,v| self.caption_before[k] = {'caption' => v} if v.is_a? String }

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

    self.editable_if ||= {}
    self.editable_if = self.editable_if.symbolize_keys


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

      opt_default = res.delete('_default')

      res.each do |name, value|
        # If defined, use the optional _default entry as the basis for all individual options,
        # allowing for a definable set of default values

        value = opt_default.merge(value) if opt_default

        i = self.new name, value, config_obj
        configs << i
      end

    end

    return configs
  end

  def calc_creatable_if obj
    calc_action_if self.creatable_if, obj
  end

  def calc_editable_if obj
    calc_action_if self.editable_if, obj
  end

  def calc_action_if action_conf, obj
    return true unless action_conf.is_a?(Hash) && action_conf.first
    all_res = Master.select(:id).where(id: obj.master.id)
    res = true

    return false if action_conf[:never]
    return true if action_conf[:always]

    action_conf.each do |c_var, c_is_res|
      c_is = {}
      c_is_res.each do |c_table, t_conds|
        table_name = c_table.gsub('__', '_').gsub('dynamic_model_', '').to_sym
        c_is[table_name] ||= {}
        t_conds.each do |field, val|

          if val.is_a? Hash

            if val.first.first == 'this'
              val = obj.attributes[val.first.last]
            end
          end
          c_is[table_name][field] = val
        end
      end

      j = c_is_res.keys.map(&:to_sym)
      q = all_res.joins(j)
      c_var = c_var.to_sym
      if c_var == :all
        res &&= !!q.where(c_is).order(id: :desc).first
      elsif c_var == :not_all
        res &&= !q.where(c_is).order(id: :desc).first
      elsif c_var == :any

        c_is.each do |ck, cv|
          res = q.where(ck => cv).order(id: :desc).first
          break if res
        end

      elsif c_var == :not_any

        c_is.each do |ck, cv|
          res &&= !q.where(ck => cv).order(id: :desc).first
          break unless res
        end

      end

      break unless res
    end


    res
  end


  protected

    def self.options_text config_obj
      config_obj.options
    end

    def self.set_defaults config_obj, all_options={}

    end

end
