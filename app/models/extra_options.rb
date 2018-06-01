class ExtraOptions

  # include CalcActions

  def self.base_key_attributes
    [:name, :config_obj, :caption_before, :show_if, :resource_name, :save_action, :view_options, :field_options, :dialog_before, :creatable_if, :editable_if, :showable_if, :valid_if]
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
        hide_unless_creatable: 'true | false to hide add-item buttons in activity logs if they are not creatable',
        data_attribute: 'string or list of fields to use as the data attribute',
        always_embed_reference: 'reference name to always show embedded'
      },
      save_action: {
        label: 'button label',
        on_update: {
          create_next_creatable: true,
          show_panel: 'panel / category name',
          hide_panel: 'panel / category name'
        },
        on_create: {},
        on_save: {
          notes: 'on_save: provides a shorthand for on_create and on_update. on_create and on_update override on_save configurations.'
        }
      },
      field_options: {
        field_name: {
          include_blank: 'true or false to force a drop down field to include a selectable blank',
          pattern: "provide a mask for a text field"
        }
      },
      dialog_before: {
        field_name: {name: "message template name", label: "show dialog button label" },
        all_fields: {name: "message template name", label: "show dialog button label" },
        submit: {name: "message template name", label: "show dialog button label" }
      },
      creatable_if: attr_for_conditions,
      editable_if: attr_for_conditions,
      showable_if: attr_for_conditions,
      valid_if: {
        on_save:  attr_for_validations,
        on_create: {},
        on_update: {}
      }

    }
  end

  def self.attr_for_conditions
    {

      all: {
        'model_table_name | this': {
          field_name: 'all conditional values must be true in model_table_name (any matching record unless id or other filters specified separately) or this (this record)',
          field_name_2: 'literal value | null',
          field_name_3: { this: 'attribute in this record' },
          field_name_4: { this_references: 'attribute in any referenced record' }
        }
      },
      any: {
        model_table_name: {
          field_name: 'any conditional value must be true'
        }
      },
      not_any: {
        model_table_name: {
          field_name: 'all conditional values must be false'
        }
      },
      not_all: {
        model_table_name: {
          field_name: 'any conditional value must be false'
        }
      }

    }
  end

  def self.attr_for_validations
    self.attr_for_conditions.deep_merge(
      all: {
        "model_table_name | this": {
          validation_field_name_5: { validation_type: 'validation options'}
        }
      }
    )
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
    self.resource_name = "#{config_obj.full_implementation_class_name.ns_underscore}__#{self.name}"
    self.caption_before ||= {}
    self.caption_before = self.caption_before.symbolize_keys
    self.caption_before = self.caption_before.each {|k,v| self.caption_before[k] = {:caption => v} if v.is_a? String }

    self.dialog_before ||= {}
    self.dialog_before = self.dialog_before.symbolize_keys

    self.show_if ||= {}
    self.show_if = self.show_if.symbolize_keys

    self.save_action ||= {}
    self.save_action = self.save_action.symbolize_keys

    # Make save_action.on_save the default for on_create and on_update
    os = self.save_action[:on_save]
    if os
      ou = self.save_action[:on_update] || {}
      oc = self.save_action[:on_create] || {}
      self.save_action[:on_update] = os.merge(ou)
      self.save_action[:on_create] = os.merge(oc)
    end

    self.view_options ||= {}
    self.view_options = self.view_options.symbolize_keys

    self.field_options ||= {}
    self.field_options = self.field_options.symbolize_keys

    self.creatable_if ||= {}
    self.creatable_if = self.creatable_if.symbolize_keys

    self.editable_if ||= {}
    self.editable_if = self.editable_if.symbolize_keys

    self.showable_if ||= {}
    self.showable_if = self.showable_if.symbolize_keys

    self.valid_if ||= {}
    self.valid_if = self.valid_if.symbolize_keys

    os = self.valid_if[:on_save]
    if os
      ou = self.valid_if[:on_update] || {}
      oc = self.valid_if[:on_create] || {}
      self.valid_if[:on_update] = os.merge(ou)
      self.valid_if[:on_create] = os.merge(oc)
    end

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
      res.deep_symbolize_keys!

      set_defaults config_obj, res

      opt_default = res.delete(:_default)

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
    ca = ConditionalActions.new self.creatable_if, obj
    ca.calc_action_if
  end

  def calc_reference_creatable_if ref_config, obj
    ci = ref_config[:creatable_if]
    return true unless ci
    ca = ConditionalActions.new ci, obj
    ca.calc_action_if
  end


  def calc_editable_if obj
    ca = ConditionalActions.new self.editable_if, obj
    ca.calc_action_if
  end

  def calc_showable_if obj
    ca = ConditionalActions.new self.showable_if, obj
    ca.calc_action_if
  end

  def calc_valid_if action_type, obj, return_failures: nil
    raise FphsException.new "incorrect action type requested in calc_valid_if #{action_type}" unless action_type.to_s.in?(%w(create update save))
    ca = ConditionalActions.new self.valid_if["on_#{action_type}".to_sym], obj, return_failures: return_failures
    ca.calc_action_if
  end


  protected

    def self.options_text config_obj
      config_obj.options
    end

    def self.set_defaults config_obj, all_options={}

    end

end
