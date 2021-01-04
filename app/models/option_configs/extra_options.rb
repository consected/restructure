# frozen_string_literal: true

module OptionConfigs
  # Top level definition of option configurations for dynamic class definitions
  # Consider this an abstract class to be subclassed by any dynamic options provider
  # class.
  class ExtraOptions < BaseOptions
    def self.base_key_attributes
      %i[
        name label config_obj caption_before show_if resource_name save_action view_options
        field_options dialog_before creatable_if editable_if showable_if add_reference_if valid_if
        filestore labels fields button_label orig_config
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
        '_' => '# @library category name',
        '_comments' => {
          'table' => 'describe the table',
          'fields' => {
            'field1' => 'describe the field',
            'field2' => '...'
          }
        },
        '_configurations' => {
          secondary_key: 'field name to use as a secondary key to lookup items'
        },
        '_definitions' => {
          'reusable_key' => '&anchor resusable objects for substitution in definitions'
        }
      }
    end

    def self.attr_defs
      attr_for_conditions_marker = 'ref: ** conditions reference **'
      {
        label: 'button label',
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
          alt_width_classes: 'html classes (space separated) to replace standard col-* classes',
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
            format: 'plain | markdown - for free text editor fields such as notes and description',
            config: {
              _comment: 'additional configurations for editor fields',
              toolbar_type: 'advanced - adds in additional editor toolbar controls'
            },
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

    #
    # Initialize a named option configuration, which may form one of many in a dynamic definition
    # @param [String] name - the name of the configuration
    # @param [Hash] config - the parsed options text for this individual configuration
    # @param [ActiveRecord::Base] config_obj - the definition record storing this dynamic definition & options
    def initialize(name, config, config_obj)
      @name = name
      @orig_config = config

      @config_obj = config_obj

      # Protect against invalid configurations preventing server startup
      config = {} unless config.respond_to? :each

      config.each do |k, v|
        send("#{k}=", v)
      rescue NoMethodError
        raise FphsException,
              "Prevented a bad configuration of #{self.class.name} in #{config_obj.class.name} (#{config_obj.respond_to?(:human_name) ? config_obj.human_name : config_obj.id}). #{k} is not recognized as a valid attribute."
      end

      self.label ||= name.to_s.humanize
      self.resource_name = "#{config_obj.full_implementation_class_name.ns_underscore}__#{self.name}"
      self.caption_before ||= {}
      self.caption_before = self.caption_before.symbolize_keys

      self.caption_before = self.caption_before.each do |k, v|
        if v.is_a? String

          v = Formatter::Substitution.text_to_html(v)

          self.caption_before[k] = {
            caption: v,
            edit_caption: v,
            show_caption: v
          }
        elsif v.is_a? Hash
          v.each do |mode, modeval|
            v[mode] = Formatter::Substitution.text_to_html(modeval)
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
    end

    #
    # Parse the options within a definition record, returning an array of options (subclasses of ExtraOptions)
    # @param [ActiveRecord::Base] config_obj - dynamic definition record
    # @return [Array {ExtraOptions}]
    def self.parse_config(config_obj, force_all = nil)
      config_text = config_obj.options_text

      configs = []

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

      config_obj.configurations = res.delete(:_configurations)
      config_obj.table_comments = res.delete(:_comments)

      # Only run through additional processing of comments if the
      # configuration was just saved
      handle_table_comments config_obj, res if config_obj.saved_changes? || force_all

      res.delete_if { |k, _v| k.to_s.start_with? '_definitions' }

      res.each do |name, value|
        # If defined, use the optional _default entry as the basis for all individual options,
        # allowing for a definable set of default values

        value = opt_default.merge(value) if opt_default

        i = new name, value, config_obj
        configs << i
      end

      configs
    end

    #
    # Parse _comments for table and fields.
    # If table comment is missing, use the item label.
    # Supplement missing field comments
    # with default option type config caption_before and labels.
    # Save the result back to the *config_obj.table_comments* attribute
    # @param [ActiveRecord::Base] config_obj - dynamic definition record
    # @param [Hash] res - comments hash results to update
    # @return [Hash] - comments hash
    def self.handle_table_comments(config_obj, res)
      # Clean up the incoming _comments entry, to avoid it impacting later configurations
      tc = config_obj.table_comments ||= {}

      ts = config_obj.table_comments && config_obj.table_comments[:table]

      new_tc = config_obj.name.underscore.humanize.titleize
      if ts != new_tc
        # Set a default table comment value
        config_obj.table_comments[:table] = "#{config_obj.class.name.humanize}: #{new_tc}"
      end

      default = res[:default]
      return unless default

      new_tc = default[:label] || config_obj.name.underscore.humanize.titleize
      if ts != new_tc
        # Set the table comment from the config label if it was not set
        config_obj.table_comments[:table] = "#{config_obj.class.name.humanize}: #{new_tc}"
      end

      # Get a hash of field comments to update
      fs = tc[:fields] || {}

      ls = default[:labels] || {}
      cb = default[:caption_before] || {}

      # Get a list of the columns for the table to ensure we
      # skip captioning fields that don't exist
      cols = config_obj.all_implementation_fields
      cols = cols.reject { |f| f.index(/^embedded_report_|^placeholder_/) }
      cols = cols.map(&:to_sym)

      cb.each do |k, v|
        next if fs[k]&.strip.present? || !k.in?(cols)

        if v.is_a? Hash
          # Get the most appropriate caption
          caption = v[:caption] || v[:show_caption] || v[:edit_caption]
          # If keep_label is set append the label or field name converted to a label
          caption += "\n#{ls[k] || k.to_s.humanize}" if v[:keep_label]
        elsif v.is_a? String
          caption = v
        end
        caption = caption&.strip
        next if caption.blank? || fs[k]&.strip == caption

        # Add the calculated caption back into the comments fields
        fs[k] = caption
      end

      # For any field labels that have been defined, use it if the comment
      # has not already been set explicitly or by a previous caption.
      ls.each do |k, v|
        next if fs[k]&.strip.present? || !k.in?(cols)

        caption = v
        caption = caption&.strip
        next if caption.blank? || fs[k]&.strip == caption

        fs[k] = v
      end

      return unless fs.present?

      config_obj.table_comments ||= {}
      config_obj.table_comments[:fields] = fs
    end

    def self.configs_valid?(config_obj)
      parse_config(config_obj)
      true
    rescue StandardError => e
      Rails.logger.info "Checking option configs valid failed silently: #{e}"
      false
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
end
