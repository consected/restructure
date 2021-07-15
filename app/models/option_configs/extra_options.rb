# frozen_string_literal: true

module OptionConfigs
  # Top level definition of option configurations for dynamic class definitions
  # Consider this an abstract class to be subclassed by any dynamic options provider
  # class.
  class ExtraOptions < BaseOptions
    include OptionConfigs::ExtraOptionImplementers::SaveTriggers

    ValidCalcIfKeys = %i[showable_if editable_if creatable_if add_reference_if].freeze

    def self.base_key_attributes
      %i[
        name label config_obj caption_before show_if resource_name save_action view_options
        field_options dialog_before creatable_if editable_if showable_if add_reference_if valid_if
        filestore labels fields button_label orig_config db_configs save_trigger
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

    attr_accessor(*key_attributes, :def_item)

    #
    # Initialize a named option configuration, which may form one of many in a dynamic definition
    # @param [String] name - the name of the configuration
    # @param [Hash] config - the parsed options text for this individual configuration
    # @param [ActiveRecord::Base] config_obj - the definition record storing this dynamic definition & options
    def initialize(name, config, config_obj)
      @name = name
      @orig_config = config

      self.def_item = @config_obj = config_obj

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

      self.db_configs ||= {}
      config_obj.db_configs = self.db_configs = self.db_configs.symbolize_keys

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

      clean_save_triggers
    end

    def clean_save_triggers
      self.save_trigger ||= {}
      self.save_trigger = self.save_trigger.symbolize_keys
      # Make save_trigger.on_save the default for on_create and on_update
      os = self.save_trigger[:on_save]
      if os
        ou = self.save_trigger[:on_update] || {}
        oc = self.save_trigger[:on_create] || {}
        self.save_trigger[:on_update] = os.merge(ou)
        self.save_trigger[:on_create] = os.merge(oc)
      end

      self.save_trigger[:on_upload] ||= {}
      self.save_trigger[:on_disable] ||= {}
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

    #
    # Check within the :references configuration for a *_if definition specified by the key argument
    # If it doesn't exist, return true, otherwise evaluate it and return the result
    # @param [Hash] ref_config - the references configuration from the extra options definition
    # @param [Symbol] key - a key such as :showable_if, :creatable_if within the references definition
    # @param [UserBase] obj - object to test against
    # @param [Boolean] default_if_no_config - the default value to return if no references
    #                                         configuration is defined for this key
    # @return [Boolean | Object] ConditionalAction#calc_action_if result
    def calc_reference_if(ref_config, key, obj, default_if_no_config: false)
      ci = ref_config[key]
      return default_if_no_config unless ci

      Rails.logger.debug "Checking calc_reference_if with #{key} on #{obj} with #{ci}"
      ca = ConditionalActions.new ci, obj
      ca.calc_action_if
    end

    #
    # Handle a calc_action_if evaluation for a base definition in the extra options configuration.
    # A base definition is one of the valid types specified in *ValidCalcIfKeys*, and
    # is something like :editable_if, :showable_if
    # @param [Symbol] key - onto the base level *_if config to check
    # @param [<Type>] obj - object to test against
    # @return [Boolean | Object] ConditionalAction#calc_action_if result
    def calc_if(key, obj)
      raise FphsException, "invalid calc_if key #{key}" unless key.in?(ValidCalcIfKeys)

      config = send(key)
      Rails.logger.debug "Checking calc_if with #{key} on #{obj} with #{config}"
      ca = ConditionalActions.new config, obj
      ca.calc_action_if
    end

    def reset_calc_evaluations!(obj)
      return unless @calc_if

      ValidCalcIfKeys.each do |key|
        memo_key = "#{key}-#{obj.class.name}-#{obj.id}"
        @calc_if.delete memo_key
      end
    end

    #
    # Evaluate the result of the *valid_if* configuration, based on the latest
    # values for the instance (and its embedded item if there is one)
    # @param [String] action_type - the action being performed: create, update or save
    # @param [UserBase] obj - the current instance
    # @param [Hash] return_failures - a hash to receive field-level failures from evaluation
    # @return [truthy] truthy if valid
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

    #
    # Inject config libraries into the provided content
    # @param [String] content_to_update (will not be updated)
    # @return [String] updated content
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
