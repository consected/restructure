# frozen_string_literal: true

class ExtraOptions
  # include CalcActions

  def self.base_key_attributes
    %i[
      name config_obj caption_before show_if resource_name save_action view_options
      field_options dialog_before creatable_if editable_if showable_if add_reference_if valid_if
      filestore labels fields button_label
    ]
  end

  def self.add_key_attributes
    []
  end

  def self.key_attributes
    base_key_attributes + add_key_attributes
  end

  def self.editable_attributes
    key_attributes - %i[name config_obj resource_name] + [:label]
  end

  attr_accessor(*key_attributes)

  def self.top_level_defs
    {
      '_' => '#@library category name',
      '_comments' => {
        'table' => 'describe the table',
        'fields' => {
          'field1' => 'describe the field',
          'field2' => '...'
        }
      },
      '_definitions' => {
        'reusable_key' => '&anchor resusable objects for substitution in definitions'
      }
    }
  end

  def self.attr_defs
    attr_for_conditions_marker = 'ref: ** conditions reference **'
    {
      fields: %w[field_name_1 field_name_2],
      button_label: 'add record button label',
      caption_before: {
        field_name: 'string caption to appear before field',
        all_fields: 'caption to appear before all fields',
        submit: 'caption to appear before submit button',
        field_to_retain_label: {
          keep_label: true,
          caption: 'caption to appear before label'
        },
        field_with_different_views: {
          show_caption: 'caption in show mode',
          edit_caption: 'caption in edit mode'
        },
        reference_with_reference_name: 'add caption above a reference action / list where the reference is named reference_<reference name>'

      },
      labels: {
        field_name: 'label to show'
      },
      show_if: {
        field_name: {
          depends_on_field_name: 'conditional value',
          current_mode: 'show | edit'
        }
      },
      view_options: {
        show_embedded_at_top: 'true | false to position a single auto loaded embedded item',
        hide_unless_creatable: 'true | false to hide add-item buttons in activity logs if they are not creatable',
        data_attribute: 'string or list of fields to use as the data attribute',
        always_embed_reference: 'reference name to always show embedded',
        always_embed_creatable_reference: 'reference name to always show embedded during new/create',
        alt_order: 'string or list of date / time or integer fields to use for ordering',
        show_cancel: 'show cancel button alongside save button',
        only_create_as_reference: 'prevent creation as a standalone item, only embedded / referenced within another',
        view_handlers: 'name of handler for UI and models (options include: address, contact, subject)',
        header_caption: 'header caption to use - can include {{substition}}',
        extra_class: 'html classes (space separated) to add to block'
      },
      filestore: {
        container: {

        }
      },
      save_action: {
        label: 'button label',
        on_update: {
          create_next_creatable: {
            if: attr_for_conditions_marker
          },
          show_panel: {
            value: 'panel / category name',
            if: attr_for_conditions_marker
          },
          hide_panel: {
            value: 'panel / category name',
            if: attr_for_conditions_marker
          },
          refresh_panel: {
            value: 'panel / category name',
            if: attr_for_conditions_marker
          }

        },
        on_create: {},
        on_save: {
          notes: 'on_save: provides a shorthand for on_create and on_update. on_create and on_update override on_save configurations.'
        }
      },
      field_options: {
        field_name: {
          include_blank: 'true or false to force a drop down field to include a selectable blank',
          pattern: 'provide a mask for a text field',
          value: 'default value | now() | today()',
          no_downcase: 'true to prevent downcasing of the attribute when stored to the database',
          edit_as: {
            field_type: 'alternative field name to use for selection of edit field',
            alt_options: 'optional specification of options for a select_ type field to use instead of general selection specified list. {Label: value, ...} or [Label,...]. For the latter the Label is downcased automatically to generate the value'
          },
          calculate_with: {
            sum: []
          }
        }
      },
      dialog_before: {
        field_name: { name: 'message template name', label: 'show dialog button label' },
        all_fields: { name: 'message template name', label: 'show dialog button label' },
        submit: { name: 'message template name', label: 'show dialog button label' }
      },
      creatable_if: attr_for_conditions_marker,
      editable_if: attr_for_conditions_marker,
      showable_if: attr_for_conditions_marker,
      add_reference_if: attr_for_conditions_marker,
      valid_if: {
        on_save: attr_for_validations,
        on_create: {
          hide_error: 'true|false (default false) to hide an error associated with this validation'
        },
        on_update: {}
      },

      "** conditions reference **": attr_for_conditions
    }
  end

  def self.attr_for_conditions
    {

      all: {
        'model_table_name | this | this_references | parent_references | referring_record (the record referring to this one)': {
          field_name: 'all conditional values must be true in model_table_name (any matching record unless id or other filters specified separately) or this (this record)',
          field_name_2: 'literal value | null',
          field_name_3: { this: 'attribute in this record' },
          field_name_4: { this_references: 'attribute in any referenced record' },
          return_constant: 'value to return if previous condition matches',
          field_to_return: 'return_value',
          field_to_return_if_also_a_condition: %w[match1 match2 return_value],
          list_field_to_return: 'return_value_list',
          return: 'return_result (return the actual matched instance)'
        }
      },
      any: {
        model_table_name: {
          field_name: 'any conditional value must be true',
          field_name_2: {
            condition: " one of #{(ConditionalActions::ValidExtraConditions + ConditionalActions::ValidExtraConditionsArrays).join(', ')}",
            not: 'true|false (optional, default false) negate the result',
            value: 'any value, with defaults or substitutions, or a hash reference to another table field'
          }
        },
        'all|any|not_all|not_any': {
          'nested conditions...': {}
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
      },
      'all_2|not_any_3...': 'allows for repeat of the condition type',
      'all|any|not_all|not_any': [
        {
          repeated_model_table_name: {}
        },
        {
          repeated_model_table_name: {}
        }
      ]

    }
  end

  def self.attr_for_validations
    {
      "ref: conditions": '** ref: conditions',
      all: {
        "model_table_name | this": {
          validation_field_name_5: { validation_type: 'validation options' }
        }
      }
    }
  end

  def initialize(name, config, config_obj)
    @name = name

    @config_obj = config_obj
    config.each do |k, v|
      send("#{k}=", v)
    rescue NoMethodError
      raise FphsException, "Prevented a bad configuration of #{self.class.name} in #{config_obj.class.name} (#{config_obj.respond_to?(:human_name) ? config_obj.human_name : config_obj.id}). #{k} is not recognized as a valid attribute."
    end
    self.resource_name = "#{config_obj.full_implementation_class_name.ns_underscore}__#{self.name}"
    self.caption_before ||= {}
    self.caption_before = self.caption_before.symbolize_keys

    self.caption_before = self.caption_before.each do |k, v|
      if v.is_a? String

        v = Admin::MessageTemplate.text_to_html(v)

        self.caption_before[k] = {
          caption: v,
          edit_caption: v,
          show_caption: v
        }
      elsif v.is_a? Hash
        v.each do |mode, modeval|
          v[mode] = Admin::MessageTemplate.text_to_html(modeval)
        end
      end
    end

    self.dialog_before ||= {}
    self.dialog_before = self.dialog_before.symbolize_keys

    self.labels ||= {}
    self.labels = self.labels.symbolize_keys

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

    # Allow field_options.edit_as.alt_options to be an array
    self.field_options.each do |k, v|
      ao = nil
      ao = v[:edit_as][:alt_options] if v && v[:edit_as]
      next unless ao.is_a? Array

      new_ao = {}
      ao.each do |aov|
        new_ao[aov.to_s.to_sym] = aov.to_s.downcase
      end
      self.field_options[k][:edit_as][:alt_options] = new_ao
    end

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

    self.filestore ||= {}
    self.filestore = self.filestore.symbolize_keys

    self.fields ||= []

    self
  end

  def self.parse_config(config_obj)
    config_text = options_text(config_obj)

    configs = []
    begin
      if config_text.present?
        config_text = include_libraries(config_text)
        begin
          res = YAML.safe_load(config_text, [], [], true)
        rescue Psych::SyntaxError => e
          linei = 0
          errtext = config_text.split(/\n/).map { |l| "#{linei += 1}: #{l}" }.join("\n")
          Rails.logger.warn e
          Rails.logger.warn errtext
          raise e
        end
      else
        res = {}
      end
      res.deep_symbolize_keys!

      set_defaults config_obj, res

      opt_default = res.delete(:_default)

      config_obj.table_comments = res.delete(:_comments)

      res.delete_if { |k, _v| k.to_s.start_with? '_definitions' }

      res.each do |name, value|
        # If defined, use the optional _default entry as the basis for all individual options,
        # allowing for a definable set of default values

        value = opt_default.merge(value) if opt_default

        i = new name, value, config_obj
        configs << i
      end
    end

    configs
  end

  def calc_creatable_if(obj)
    Rails.logger.debug "Checking calc_creatable_if on #{obj} with #{self.creatable_if}"
    ca = ConditionalActions.new self.creatable_if, obj
    ca.calc_action_if
  end

  def calc_reference_creatable_if(ref_config, obj)
    ci = ref_config[:creatable_if]
    return true unless ci

    Rails.logger.debug "Checking calc_reference_creatable_if on #{obj} with #{ci}"
    ca = ConditionalActions.new ci, obj
    ca.calc_action_if
  end

  def calc_reference_prevent_disable_if(ref_config, obj)
    ci = ref_config[:prevent_disable]
    return false unless ci

    Rails.logger.debug "Checking calc_reference_prevent_disable_if on #{obj} with #{ci}"
    ca = ConditionalActions.new ci, obj
    ca.calc_action_if
  end

  def calc_reference_allow_disable_if_not_editable_if(ref_config, obj)
    ci = ref_config[:allow_disable_if_not_editable]
    return false unless ci

    Rails.logger.debug "Checking calc_reference_allow_disable_if_not_editable_if on #{obj} with #{ci}"
    ca = ConditionalActions.new ci, obj
    ca.calc_action_if
  end

  def calc_editable_if(obj)
    Rails.logger.debug "Checking calc_editable_if on #{obj} with #{self.editable_if}"
    ca = ConditionalActions.new self.editable_if, obj
    ca.calc_action_if
  end

  def calc_add_reference_if(obj)
    Rails.logger.debug "Checking calc_add_reference_if on #{obj} with #{add_reference_if}"
    ca = ConditionalActions.new add_reference_if, obj
    ca.calc_action_if
  end

  def calc_showable_if(obj)
    ca = ConditionalActions.new self.showable_if, obj
    ca.calc_action_if
  end

  def calc_valid_if(action_type, obj, return_failures: nil)
    unless action_type.to_s.in?(%w[create update save])
      raise FphsException, "incorrect action type requested in calc_valid_if #{action_type}"
    end

    ci = self.valid_if["on_#{action_type}".to_sym]
    Rails.logger.debug "Checking calc_valid_if on #{obj} with #{ci}"
    ca = ConditionalActions.new ci, obj, return_failures: return_failures
    ca.calc_action_if
  end

  # Get an array of ConfigLibrary objects from the options text
  def self.config_libraries(config_obj)
    c = options_text(config_obj).dup
    return [] unless c.present?

    format = config_obj.is_a?(Report) ? :sql : :yaml

    Admin::ConfigLibrary.make_substitutions! c, format
  end

  def self.options_text(config_obj)
    if config_obj.is_a?(Report)
      config_obj.sql.dup
    else
      config_obj.options.dup
    end
  end

  def self.set_defaults(config_obj, all_options = {}); end

  def self.include_libraries(content_to_update)
    content_to_update = content_to_update.dup
    reg = /# @library\s+([^\s]+)\s+([^\s]+)\s*$/
    res = content_to_update.match reg

    while res
      category = res[1].strip
      name = res[2].strip
      lib = Admin::ConfigLibrary.content_named category, name, format: :yaml
      lib = lib.dup
      lib.gsub!(/^_definitions:.*/, "_definitions__#{category}_#{name}:")
      content_to_update.gsub!(res[0], lib)
      res = content_to_update.match reg
    end

    content_to_update
  end
end
