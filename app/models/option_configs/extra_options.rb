# frozen_string_literal: true

module OptionConfigs
  # Top level definition of option configurations for dynamic class definitions
  # Consider this an abstract class to be subclassed by any dynamic options provider
  # class.
  class ExtraOptions < BaseOptions
    include OptionConfigs::ExtraOptionImplementers::SaveTriggers

    ValidCalcIfKeys = %i[showable_if editable_if creatable_if add_reference_if].freeze
    ValidValidIfTriggers = %i[on_create on_save on_update].freeze
    ValidSaveTriggerTriggers = %i[before_save on_create on_save on_update on_upload on_disable].freeze
    LibraryMatchRegex = /# @library\s+([^\s]+)\s+([^\s]+)\s*$/
    ValidFieldConfigs = %i[db_configs field_options labels caption_before dialog_before show_if].freeze

    def self.base_key_attributes
      %i[
        name label config_obj caption_before show_if resource_name resource_item_name save_action view_options
        field_options dialog_before creatable_if editable_if showable_if add_reference_if valid_if
        filestore labels fields button_label orig_config db_configs save_trigger embed references
        show_if_condition_strings batch_trigger config_trigger preset_fields field_configs raw_field_configs
        set_variables
      ]
    end

    def self.add_key_attributes
      []
    end

    def self.key_attributes
      base_key_attributes + add_key_attributes
    end

    def self.editable_attributes
      key_attributes - %i[name config_obj resource_name resource_item_name] + [:label]
    end

    attr_accessor(*key_attributes, :def_item, :bad_ref_items)

    #
    # Initialize a named option configuration, which may form one of many in a dynamic definition
    # @param [String] name - the name of the configuration
    # @param [Hash] config - the parsed options text for this individual configuration
    # @param [ActiveRecord::Base] config_obj - the definition record storing this dynamic definition & options
    def initialize(name, config, config_obj)
      super()
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

      begin
        self.resource_name = "#{config_obj.full_implementation_class_name.ns_underscore}__#{self.name}"
        self.resource_item_name = resource_name
        clean_fields_def
        clean_field_configs

        clean_label_def
        clean_caption_before_def
        clean_dialog_before_def
        clean_labels_def
        clean_show_if_def
        clean_save_action_def
        clean_view_options_def
        clean_db_configs_def
        clean_access_if_def
        clean_valid_if_def
        clean_filestore_def
        clean_field_options_def
        clean_embed_def
        clean_references_def
        clean_save_triggers
        clean_batch_triggers
        clean_config_triggers
        clean_preset_fields
        clean_set_variables_def

        # Add the cleaned values back into field_configs - save a raw version for use elsewhere
        # This needs to be "deep cloned", to avoid a simple clone just copying references
        # Using Marshal for deep cloning is safe here since we're only operating on data already in memory
        self.raw_field_configs = Marshal.load(Marshal.dump(field_configs))
        add_field_configs_from_standalone_defs
      rescue StandardError => e
        Rails.logger.warn "Failed to initialize ExtraOptions for #{@name}: #{e}"
        Rails.logger.warn e.short_string_backtrace
        raise FphsOptionsGeneralError, "Failed to initialize ExtraOptions for #{@name}: #{e}", e.backtrace
      end
    end

    # Defintion label
    def clean_label_def
      self.label ||= @name.to_s.humanize
    end

    def clean_caption_before_def
      self.caption_before ||= {}
      self.caption_before = self.caption_before.symbolize_keys

      self.caption_before = self.caption_before.each do |k, v|
        if v.is_a? String

          v = Formatter::Substitution.text_to_html(v).strip

          self.caption_before[k] = {
            caption: v,
            edit_caption: v,
            show_caption: v,
            new_caption: v
          }
        elsif v.is_a? Hash
          v.each do |mode, modeval|
            v[mode] = Formatter::Substitution.text_to_html(modeval).to_s.strip
          end

          v[:new_caption] = v[:edit_caption] unless v.key?(:new_caption)
        end
      end
    end

    def clean_dialog_before_def
      self.dialog_before ||= {}
      self.dialog_before = self.dialog_before.symbolize_keys

      dialog_before.transform_values! { |v| v.is_a?(String) ? { name: v } : v }
      dialog_before.each do |k, v|
        unless v.is_a? Hash
          failed_config :dialog_before,
                        "dialog_before must be a Hash { name: '<template name>' } or String: #{k}",
                        level: :error
          next
        end

        name = v[:name]
        mt = Admin::MessageTemplate.active.find_by(name:)
        next if mt

        failed_config :dialog_before,
                      "dialog_before specifies a named message template that doesn't exist: #{name}",
                      level: :warn
      end
    end

    # Field labels definitions
    def clean_labels_def
      self.labels ||= {}
      self.labels = self.labels.symbolize_keys
    end

    def clean_show_if_def
      self.show_if ||= {}

      show_if_condition_strings&.each do |fn, val|
        # Generate a real show_if hash fs a condition string was provided
        # and show if is not already set
        next if val.nil? || val.empty? || self.show_if[fn]

        begin
          bl = Redcap::DataDictionaries::BranchingLogic.new(val)
          sis = bl&.generate_show_if
          self.show_if[fn] = sis if sis.present?
        rescue StandardError => e
          Rails.logger.warn "Failed to generate real show_if (in #{@config_obj&.resource_name}) " \
                            "for #{fn}: #{val}\n#{e}"
          self.show_if[fn] = { generate_show_if: "failed - #{e}" }
        end
      end

      self.show_if = self.show_if.symbolize_keys
    end

    def clean_save_action_def
      self.save_action ||= {}
      self.save_action = self.save_action.symbolize_keys

      # Make save_action.on_save the default for on_create and on_update
      os = self.save_action[:on_save]
      return unless os

      ou = self.save_action[:on_update] || {}
      oc = self.save_action[:on_create] || {}
      self.save_action[:on_update] = os.merge(ou)
      self.save_action[:on_create] = os.merge(oc)
    end

    def clean_view_options_def
      self.view_options ||= {}
      self.view_options = self.view_options.symbolize_keys
    end

    def clean_db_configs_def
      self.db_configs ||= {}
      @config_obj.db_columns ||= self.db_configs = self.db_configs.symbolize_keys if @config_obj.respond_to? :db_columns
    end

    #
    # Clean the fields definition. This intentionally does not override the dynamic model field list
    # or external identifier extra fields list. The fields definition is intended to be a list of
    # fields that are presented to the end user, and may be a subset of the fields in the model.
    def clean_fields_def
      self.fields ||= []
    end

    def clean_field_options_def
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
    end

    def clean_filestore_def
      self.filestore ||= {}
      self.filestore = self.filestore.symbolize_keys
    end

    def clean_access_if_def
      self.creatable_if ||= {}
      self.creatable_if = self.creatable_if.symbolize_keys

      self.editable_if ||= {}
      self.editable_if = self.editable_if.symbolize_keys

      self.showable_if ||= {}
      self.showable_if = self.showable_if.symbolize_keys
    end

    def clean_valid_if_def
      self.valid_if ||= {}
      self.valid_if = self.valid_if.symbolize_keys

      unless self.valid_if.keys.empty? || (self.valid_if.keys - ValidValidIfTriggers).empty?
        failed_config :valid_if,
                      "valid_if contains invalid keys #{valid_if.keys} - expected only:",
                      extra_details: ValidValidIfTriggers
      end

      os = self.valid_if[:on_save]
      return unless os

      ou = self.valid_if[:on_update] || {}
      oc = self.valid_if[:on_create] || {}
      self.valid_if[:on_update] = os.merge(ou)
      self.valid_if[:on_create] = os.merge(oc)
    end

    def clean_embed_def
      return unless embed

      if embed == 'default_embed_resource'
        rn = config_obj.default_embed_resource_name(name)
        self.embed = { resource_name: rn }
      elsif embed.is_a?(String)
        rn = embed
        self.embed = { resource_name: rn }
      else
        rn = embed[:resource_name]
      end

      resource = Resources::Models.find_by(resource_name: rn)
      embed[:resource_model_def] = resource

      return if resource && resource[:model]

      Rails.logger.warn "embed for #{rn} does not exist as a class in #{name} / #{config_obj.name}"
      # Log this as a warning, not an error, since we are not able to control the order of items being created
      # in an app import, and many references to underlying definitions will not yet have been created
      failed_config :embed,
                    "embed for #{rn} does not exist as a class in #{name} / #{config_obj.name}",
                    level: :warn
    end

    def clean_references_def
      return unless references

      new_ref = {}
      if references.is_a? Array
        references.each do |refitem|
          # Make all keys singular, to simplify configurations
          add_refitem = {}
          refitem.each do |k, _v|
            if k.to_s != k.to_s.singularize
              new_k = k.to_s.singularize.to_sym
              add_refitem[new_k] = refitem.delete(k)
            end
          end

          refitem.merge! add_refitem

          refitem.each do |k, v|
            vi = v[:add_with] && v[:add_with][:extra_log_type]
            ckey = k.to_s
            ckey += "_#{vi}" if vi
            new_ref[ckey.to_sym] = { k => v }
          end
        end
      else
        new_ref = {}
        fix_refs = {}

        # Make all keys singular, to simplify configurations
        # The changes can't be made directly inside the iteration, so handle it in two steps
        references.each do |k, _v|
          fix_refs[k] = references[k] if k.to_s != k.to_s.singularize
        end

        fix_refs.each do |k, _v|
          new_k = k.to_s.singularize.to_sym
          references[new_k] = references.delete(k)
        end

        references.each do |k, v|
          vi = v[:add_with] && v[:add_with][:extra_log_type]
          ckey = k.to_s
          ckey += "_#{vi}" if vi
          new_ref[ckey.to_sym] = { k => v }
        end
      end

      self.references = new_ref

      references.each do |_k, refitem|
        self.bad_ref_items = []
        refitem.each do |mn, conf|
          to_class = ModelReference.to_record_class_for_type(mn)

          # Avoid breaking app type imports if the resource being pointed to in the reference
          # hasn't been set up yet.
          if to_class.nil? || (to_class.respond_to?(:definition) && !to_class.definition)
            Rails.logger.warn "Definition for class #{to_class} is not set - skipping reference setup for #{mn}"
            break
          end

          if to_class
            elt = conf[:add_with] && conf[:add_with][:extra_log_type]
            add_with_elt = nil
            add_with_elt = to_class.human_name_for(elt) if elt && to_class.respond_to?(:human_name_for)
            refitem[mn][:to_record_label] = conf[:result_label] || conf[:label] || add_with_elt || to_class.human_name

            if to_class.respond_to?(:no_master_association)
              refitem[mn][:no_master_association] = to_class.no_master_association
            end

            refitem[mn][:to_model_name_us] = to_class.to_s&.ns_underscore
            refitem[mn][:to_model_class_name] = to_class.to_s
            refitem[mn][:to_table_name] = to_class.table_name
            nil

            if to_class.respond_to?(:definition)
              cd = to_class.definition
              tsn = cd.schema_name
              tct = cd.class.to_s
              refitem[mn][:to_schema_name] = tsn
              refitem[mn][:to_class_type] = tct
            end
          else
            bad_ref_items << mn
            Rails.logger.warn "extra log type reference for #{mn} does not exist as a class in #{name} / #{config_obj.name}"
            Rails.logger.info 'Will clean up reference to avoid it being used again in this session'
            # Log this as a warning, not an error, since we are not able to control the order of items being created
            # in an app import, and many references to underlying definitions will not yet have been created
            failed_config :references,
                          "reference for #{mn} does not exist as a class in #{name} / #{config_obj.name}",
                          level: :warn
          end
        end

        # Cleanup bad items
        bad_ref_items.each do |br|
          refitem.delete(br)
        end
      end
    end

    #
    # Get the model reference configuration hash, based on the to_record.
    # For flexibility, this may be keyed with a singular or plural key that is one of:
    # the full activity log with extra log type (for example activity_log__player_contact_step_1)
    # the database table name (for example activity_log_player_contacts)
    # the model resource name (for example activity_log__player_contact)
    def model_reference_config(model_reference)
      return unless references

      references[model_reference.to_record_result_key.to_sym] ||
        references[model_reference.to_record.class.table_name.singularize.to_sym] ||
        references[model_reference.to_record.class.name.ns_underscore.singularize.to_sym]
    end

    def clean_save_triggers
      self.save_trigger ||= {}
      self.save_trigger = self.save_trigger.symbolize_keys

      unless self.save_trigger.keys.empty? || (self.save_trigger.keys - ValidSaveTriggerTriggers).empty?
        failed_config :save_trigger,
                      "save_trigger contains invalid keys #{save_trigger.keys} - expected only:",
                      extra_details: ValidSaveTriggerTriggers
      end

      # Make save_trigger.on_save the default for on_create and on_update
      os = self.save_trigger[:on_save]
      if os
        os = [os] if os.is_a?(Hash)

        ou = self.save_trigger[:on_update]
        oc = self.save_trigger[:on_create]
        ou = [ou] if ou.is_a?(Hash)
        oc = [oc] if oc.is_a?(Hash)

        ou ||= []
        oc ||= []
        self.save_trigger[:on_update] = os + ou
        self.save_trigger[:on_create] = os + oc
      end

      self.save_trigger[:on_upload] ||= {}
      self.save_trigger[:on_disable] ||= {}
    end

    def clean_batch_triggers
      self.batch_trigger ||= {}
      self.batch_trigger = self.batch_trigger.symbolize_keys
      self.batch_trigger[:on_record] ||= {}
    end

    def clean_config_triggers
      self.config_trigger ||= {}
      self.config_trigger = self.config_trigger.symbolize_keys
      od = self.config_trigger[:on_define] ||= []

      self.config_trigger[:on_define] = [od] unless od.is_a?(Array)
    end

    def clean_preset_fields
      self.preset_fields ||= {}
      self.preset_fields = self.preset_fields.symbolize_keys
    end

    #
    # Validate and clean the set_variables definition.
    # set_variables accepts an ordered array of variable definitions,
    # each with :name, :value, and optional :if condition.
    def clean_set_variables_def
      return if set_variables.blank?

      unless set_variables.is_a?(Array)
        failed_config :set_variables, 'must be an array of variable definitions'
        self.set_variables = []
        return
      end

      self.set_variables = set_variables.map do |entry|
        entry = entry.symbolize_keys if entry.is_a?(Hash)
        unless entry.is_a?(Hash) && entry[:name].present? && entry.key?(:value)
          failed_config :set_variables, "each entry must have 'name' and 'value' keys"
          next nil
        end
        entry
      end.compact
    end

    def clean_field_configs
      fla = fields
      if field_configs.nil?
        self.field_configs = {}
      else
        # 'field_configs' was explicitly set, so use it to set the appropriate configurations
        # for each of the valid_configs
        self.field_configs ||= {}
        self.field_configs = self.field_configs.symbolize_keys
        failed = false
        field_configs.each do |fname, fconfig|
          unless fconfig&.is_a? Hash
            failed_config :field_configs, "field '#{fname}' is not a Hash"
            failed = true
            self.field_configs[fname] = {}
            next
          end

          ValidFieldConfigs.each do |vc|
            # For each of the ValidFieldConfigs, add the corresponding definition to the
            #  named attribute
            c = fconfig[vc]
            next unless c

            ivar = instance_variable_get("@#{vc}")
            unless ivar
              instance_variable_set("@#{vc}", {})
              ivar = instance_variable_get("@#{vc}")
            end

            ivar.merge!(fname => c)
          end
        end

        return if failed

      end

      # Build the list of errors from the explicitly defined field_configs
      efs = field_configs.keys.map(&:to_s) - fla
      if efs.present?
        failed_config :field_configs, 'field_configs includes fields that are not in the field list:',
                      extra_details: efs
      end

      field_configs.each do |fname, fconfig|
        extra_keys = fconfig.keys - ValidFieldConfigs
        next if extra_keys.empty?

        failed_config :field_configs,
                      "field_configs for #{fname} includes invalid keys: #{extra_keys} - expected only:",
                      extra_details: ValidFieldConfigs
      end

      # Now that the field_configs errors have been checked for the explicitly definition,
      # go ahead and merge in the values from the standalone definitions
      add_field_configs_from_standalone_defs
    end

    # Set field_configs from the configurations listed in ValidFieldConfigs
    # for each of the valid fields
    def add_field_configs_from_standalone_defs
      fla = fields

      self.field_configs ||= {}
      ValidFieldConfigs.each do |vc|
        c = instance_variable_get("@#{vc}")
        next unless c

        c.symbolize_keys.each do |k, v|
          # Only include valid fields from the field_list_array
          # NOTE: this excludes caption_before 'all_fields' and 'submit'
          next unless fla.include?(k.to_s)

          field_configs[k] ||= {}
          field_configs[k].merge!({ vc => v })
        end
      end
    end

    # Check if any of the configs were bad
    # This should be extended to provide additional checks when options are saved
    # @todo - work out why the "raise" was disabled and whether it needs changing
    def self.raise_bad_configs(object_instance_or_config)
      ces = all_option_configs_errors(object_instance_or_config)
      return unless ces

      Rails.logger.warn("Bad #{name} configurations: #{ces}")
      raise FphsOptionsBadConfig, "Bad configurations in #{name}"
      ces
    end

    def self.bad_configs?(object_instance_or_config)
      !!all_option_configs_errors(object_instance_or_config)
    end

    #
    # Parse the options within a definition record, returning an array of options (subclasses of ExtraOptions)
    # @param [ActiveRecord::Base] config_obj - dynamic definition record
    # @return [Array {ExtraOptions}]
    def self.parse_config(config_obj, force_all = nil)
      loaded_config = parse_options_text(config_obj)
      # Configurations need to be set in order for
      # defaults to be set correctly
      config_obj.configurations = options_based_on_keys_stating_with('_configurations', loaded_config)

      set_defaults config_obj, loaded_config

      config_obj.table_comments = loaded_config.delete(:_comments)
      config_obj.db_columns = loaded_config.delete(:_db_columns)
      config_obj.data_dictionary = loaded_config.delete(:_data_dictionary)
      config_obj.options_constants = loaded_config.delete(:_constants)

      # Definitions '_definitions...' are only used by YAML for the definition of anchors
      # and so will already by incorporated into the relevant configurations.
      loaded_config.delete_if { |k, _v| k.to_s.start_with? '_definitions' }

      configs = handle_defaults_merges_overrides(config_obj, loaded_config)
      # Update comments for table and fields, based on the default option type configuration
      # after all the _default, _merge_... and _override processing has been completed
      handle_table_comments_just_if_saved(config_obj, configs, force_all)

      configs
    rescue FphsException => e
      raise FphsException, e
    end

    #
    # Prepare the options text from the dynamic definition, incorporating standard definitions and libraries
    # @param [ActiveRecord::Base] config_obj - dynamic definition record
    # @return [String] full options text
    def self.prepare_options_text(config_obj)
      config_text = config_obj.options_text
      return unless config_text.present?

      config_text = config_text.gsub(/^---.*\n/, '')

      # Check for redefined standard anchors before processing
      redefined_anchors = check_for_redefined_anchors(config_obj.options_text)
      if redefined_anchors.any?
        anchor_list = redefined_anchors.map { |a| "&#{a}" }.join(', ')
        error_msg = "Configuration redefines standard anchors that should be referenced with *anchor instead: #{anchor_list}"

        # Find the specific lines with the problematic anchor redefinitions
        problem_lines = find_anchor_redefinition_lines(config_obj.options_text, redefined_anchors)

        bt = [error_msg] + [problem_lines]
        raise FphsOptionsParseError, error_msg, bt
      end

      config_text = prepend_standard_definitions(config_text)
      config_text = include_libraries(config_text)
      config_text.gsub(/^---.*\n/, '')
    end

    #
    # Parse the options text from the dynamic definition, producing an initial Hash
    # @param [ActiveRecord::Base] config_obj - dynamic definition record
    # @return [Hash] initial configuration hash
    def self.parse_options_text(config_obj)
      config_text = prepare_options_text(config_obj)

      if config_text.present?

        begin
          loaded_config = YAML.safe_load(config_text, permitted_classes: [],
                                                      permitted_symbols: [],
                                                      aliases: true)
        rescue Psych::SyntaxError, Psych::DisallowedClass, Psych::Exception => e
          linei = 0
          errtext = config_text.split("\n").map { |l| "#{linei += 1}: #{l}" }.join("\n")
          Rails.logger.warn e
          Rails.logger.warn errtext
          if Rails.env.test? || Rails.env.development?
            STDERR.puts e
            STDERR.puts errtext
          end

          bt = ["#{e.class.name} #{e}"] + [errtext]
          raise FphsOptionsParseError, "#{e.class.name} #{e} -- review failed configuration YAML", bt
        end
      else
        loaded_config = {}
      end
      loaded_config.deep_symbolize_keys!
    rescue StandardError => e
      raise if e.is_a?(FphsOptionsParseError)

      Rails.logger.error "Error occurred in parse_options_text in #{config_obj}: #{e}"
      Rails.logger.error e.short_string_backtrace
      raise FphsException,
            "Error occurred in parse_options_text in #{config_obj}: #{e}"
    end

    #
    # Create a final set of configurations for each of the main option types,
    # incorporating _default..., _merge_... and _override entries
    # @param [ActiveRecord::Base] config_obj dynamic definition record
    # @param [Hash] loaded_config configuration hash
    # @return [Array] configuration instances
    def self.handle_defaults_merges_overrides(config_obj, loaded_config)
      configs = []

      # Handle any entry starting with "_default"
      opt_default = options_based_on_keys_stating_with('_default', loaded_config)

      opt_merge_default = loaded_config.delete(:_merge_default)
      opt_merge_override = loaded_config.delete(:_merge_override)
      opt_override = loaded_config.delete(:_override)

      loaded_config.each do |name, value|
        unless name.in?(%i[primary blank_log])
          value ||= {}

          # If defined, use the optional _default entry as the basis for all individual options,
          # allowing for a definable set of default values
          value = opt_default.deep_dup.merge(value) if opt_default.present?

          # If defined, use the optional opt_merge_default entry to "deep merge" item options
          # over the merge_default items.
          value = opt_merge_default.deep_dup.deep_merge(value) if opt_merge_default

          # If defined, use the optional opt_merge_override entry to "deep merge" options
          # over the existing items.
          value = value.deep_dup.deep_merge(opt_merge_override) if opt_merge_override

          # If defined, use the optional _override entry to replace individual options.
          value = value.deep_dup.merge(opt_override) if opt_override
        end
        i = new name, value, config_obj
        configs << i
      end
      configs
    end

    # Only run through additional processing of comments if the
    # configuration was just saved
    def self.handle_table_comments_just_if_saved(config_obj, configs, force_all)
      if config_obj.saved_changes? || force_all
        # Get the default option type configuration
        default_config = configs.find { |c| c.name == config_obj.default_option_type_name }&.orig_config
        return unless default_config

        handle_table_comments config_obj, default_config
      elsif config_obj.table_comments
        config_obj.table_comments[:original_fields] = config_obj.table_comments[:fields]
      end
    end

    #
    # Parse _comments for table and fields.
    # If table comment is missing, use the item label.
    # Supplement missing field comments
    # with default option type config caption_before and labels.
    # Save the result back to the *config_obj.table_comments* attribute
    # @param [ActiveRecord::Base] config_obj - dynamic definition record
    # @param [Hash] default_config - default option type configuration hash
    # @return [Hash] - comments hash
    def self.handle_table_comments(config_obj, default_config)
      # Clean up the incoming _comments entry, to avoid it impacting later configurations
      tc = config_obj.table_comments ||= {}

      ts = config_obj.table_comments && config_obj.table_comments[:table]
      if ts.blank?
        # Set the table comment from the config label or class name if no comment was previously set
        new_tc = default_config[:label] || config_obj.name.underscore.humanize.captionize
        config_obj.table_comments[:table] = "#{config_obj.class.name.humanize}: #{new_tc}"
      end

      # Get a hash of field comments to update
      fs = tc[:fields] || {}
      original_fs = fs.dup

      ls = default_config[:labels] || {}
      cb = default_config[:caption_before] || {}

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

        fs[k] = v if fs[k].blank?
      end

      return unless fs.present?

      config_obj.table_comments ||= {}
      config_obj.table_comments[:fields] = fs
      # Keep the original configuration available, to allow
      # model generator comparisons
      config_obj.table_comments[:original_fields] = original_fs
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

      ca = ConditionalActions.new ci, obj
      ca.calc_action_if
    rescue StandardError => e
      Rails.logger.error "Error occurred while checking calc_reference_if with #{key} on #{obj} user #{obj.current_user}: #{e}"
      Rails.logger.error e.short_string_backtrace
      raise FphsCalcConditionError,
            "Error occurred while checking calc_reference_if condition - user #{obj.current_user} - time #{Time.now}: #{e}"
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
      ca = ConditionalActions.new config, obj
      ca.calc_action_if
    rescue StandardError => e
      Rails.logger.error "Error occurred while checking calc_if with #{key} on #{obj} user #{obj.current_user}: #{e}"
      Rails.logger.error e.short_string_backtrace
      raise FphsCalcConditionError,
            "Error occurred while checking calc_if condition - user #{obj.current_user} - time #{Time.now}: #{e}"
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

      ci = self.valid_if[:"on_#{action_type}"]
      Rails.logger.debug "Checking calc_valid_if on #{obj} with #{ci}"
      ca = ConditionalActions.new(ci, obj, return_failures:)
      ca.calc_action_if
    rescue StandardError => e
      Rails.logger.error "Error occurred while checking calc_valid_if with #{action_type} on #{obj} user #{obj.current_user}: #{e}"
      Rails.logger.error e.short_string_backtrace
      raise FphsCalcConditionError,
            "Error occurred while checking calc_valid_if condition on #{action_type} - user #{obj.current_user} - time #{Time.now}: #{e}"
    end

    def self.set_defaults(config_obj, all_options = {}); end

    #
    # Extract standard anchor names from standard definition files
    # @param [String] force_type - optional type to check specific standard defs file
    # @return [Array<String>] list of anchor names defined in standard files
    def self.extract_standard_anchors(force_type: nil)
      anchors = []

      # Check both extra_options and type-specific standard definitions
      types_to_check = ['extra_options']
      if force_type && force_type != 'extra_options'
        types_to_check << force_type
      elsif force_type.nil?
        # If no force_type, also check the current class type
        types_to_check << name.demodulize.underscore
      end

      types_to_check.uniq.each do |type|
        defsw = [
          'app',
          'models',
          'admin',
          'defs',
          "#{type}_standard_option_defs.yaml"
        ]
        path = Rails.root.join(*defsw)
        next unless File.exist?(path)

        content = File.read(path)
        # Match YAML anchor definitions: &anchor_name
        content.scan(/&([a-zA-Z0-9_]+)/).each do |match|
          anchors << match[0]
        end
      end

      anchors.uniq
    end

    #
    # Check if user's options text accidentally redefines any standard anchors
    # @param [String] options_text - the user's configuration YAML (before prepending standards)
    # @return [Array<String>] list of redefined anchor names, or empty array
    def self.check_for_redefined_anchors(options_text)
      return [] unless options_text.present?

      standard_anchors = extract_standard_anchors
      return [] if standard_anchors.empty?

      redefined = []

      # Check for anchor redefinitions in user's text
      # The options_text passed in should be the RAW user text before prepending standards
      standard_anchors.each do |anchor|
        # Match &anchor_name but not *anchor_name (which is a reference, not a definition)
        # Match after: start of line, whitespace, or colon (for cases like `field:&anchor`)
        redefined << anchor if options_text.match?(/(?:^|[\s:])&#{Regexp.escape(anchor)}\b/)
      end

      redefined
    end

    #
    # Find the specific lines in the options text that contain anchor redefinitions
    # @param [String] options_text - the user's configuration YAML
    # @param [Array<String>] redefined_anchors - list of anchor names that were redefined
    # @return [String] formatted string showing line numbers and content of problematic lines
    def self.find_anchor_redefinition_lines(options_text, redefined_anchors)
      return '' unless options_text.present? && redefined_anchors.any?

      lines = options_text.split("\n")
      problem_lines = []

      redefined_anchors.each do |anchor|
        # Find all lines that contain this anchor redefinition
        lines.each_with_index do |line, idx|
          if line.match?(/(?:^|[\s:])&#{Regexp.escape(anchor)}\b/)
            line_num = idx + 1
            problem_lines << "#{line_num}: #{line}"
          end
        end
      end

      problem_lines.uniq.join("\n")
    end

    #
    # Add standard definitions that simplify configurations
    def self.prepend_standard_definitions(content_to_update, force_type: nil)
      return unless content_to_update

      # First time through we ensure the common extra options defaults are added
      content_to_update = prepend_standard_definitions(content_to_update, force_type: 'extra_options') unless force_type

      new_force_type ||= name.demodulize.underscore
      # Ensure we don't include extra_options defaults twice
      return content_to_update if force_type.nil? && new_force_type == 'extra_options'

      force_type ||= new_force_type

      defsw = [
        'app',
        'models',
        'admin',
        'defs',
        "#{force_type}_standard_option_defs.yaml"
      ]

      path = Rails.root.join(*defsw)
      return content_to_update unless File.exist?(path)

      defs_yaml = File.read(path)
      "# @#{force_type}_standard_definitions_start\n#{defs_yaml}\n# @#{force_type}_standard_definitions_end\n#{content_to_update}\n"
    end

    #
    # Inject config libraries into the provided content
    # @param [String] content_to_update (will not be updated)
    # @return [String] updated content
    def self.include_libraries(content_to_update)
      return unless content_to_update

      content_to_update = content_to_update.dup
      reg = LibraryMatchRegex
      res = content_to_update.match reg

      while res
        category = res[1].strip
        name = res[2].strip
        lib = Admin::ConfigLibrary.content_named category, name, format: :yaml
        lib = (lib || '').dup
        lib.gsub!(/^_definitions:.*/, "_definitions__#{category}_#{name}:")
        lib = "# @sourced_library_start #{category} #{name}\n#{lib}\n# @sourced_library_end #{category} #{name}\n"
        content_to_update.gsub!(res[0], lib)
        res = content_to_update.match reg
      end

      content_to_update
    end

    #
    # Find referenced libraries into the provided content
    # @param [String] content
    # @return [Array{Hash}] array of hashes {category:, name:}
    def self.requested_libraries(content)
      reshashes = []
      content = content.dup
      reg = LibraryMatchRegex
      res = content.match reg

      while res
        category = res[1].strip
        name = res[2].strip
        reshashes << { category:, name: }
        content.gsub!(res[0], '')
        res = content.match reg
      end

      reshashes
    end

    #
    # Set up a hash of options for keys starting with a certain string.
    # Delete the found options for the loaded configuration
    # @param [String] keys_start_with The prefix string to match keys against
    # @param [Hash] loaded_config The configuration hash to process
    # @return [Hash] A hash of options extracted from the loaded configuration
    def self.options_based_on_keys_stating_with(keys_start_with, loaded_config)
      options = {}
      loaded_config.each_key do |k|
        next unless k.to_s.start_with? keys_start_with

        merge_hash = loaded_config.delete(k)
        next unless merge_hash.is_a? Hash

        options.merge!(merge_hash)
      end
      options
    end
  end
end
