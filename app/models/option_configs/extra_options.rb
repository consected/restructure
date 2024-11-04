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

    def self.base_key_attributes
      %i[
        name label config_obj caption_before show_if resource_name resource_item_name save_action view_options
        field_options dialog_before creatable_if editable_if showable_if add_reference_if valid_if
        filestore labels fields button_label orig_config db_configs save_trigger embed references
        show_if_condition_strings batch_trigger config_trigger preset_fields
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

      self.resource_name = "#{config_obj.full_implementation_class_name.ns_underscore}__#{self.name}"
      self.resource_item_name = resource_name

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
      clean_fields_def
      clean_field_options_def
      clean_embed_def
      clean_references_def
      clean_save_triggers
      clean_batch_triggers
      clean_config_triggers
      clean_preset_fields
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

      dialog_before.each do |k, v|
        unless v.is_a? Hash
          failed_config :dialog_before,
                        "dialog_before must be a Hash: #{k}",
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
                      "valid_if contains invalid keys #{valid_if.keys} - expected only #{ValidValidIfTriggers}"
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
          if to_class.nil? || to_class.respond_to?(:definition) && !to_class.definition
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
            tsn = nil

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
                      "save_trigger contains invalid keys #{save_trigger.keys} - expected only #{ValidSaveTriggerTriggers}"
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
      self.config_trigger = self.config_trigger.symbolize_keys
      self.config_trigger[:on_define] ||= {}
    end

    def clean_preset_fields
      self.preset_fields ||= {}
      self.preset_fields = self.preset_fields.symbolize_keys
    end

    # Check if any of the configs were bad
    # This should be extended to provide additional checks when options are saved
    # @todo - work out why the "raise" was disabled and whether it needs changing
    def self.raise_bad_configs(option_configs)
      ces = all_option_configs_errors(option_configs)
      return unless ces

      Rails.logger.warn("Bad #{name} configurations: #{ces}")
      raise FphsException, "Bad configurations in #{name}"
      ces
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
          res = YAML.safe_load(config_text, permitted_classes: [],
                                            permitted_symbols: [],
                                            aliases: true)
        rescue Psych::SyntaxError, Psych::DisallowedClass, Psych::Exception => e
          linei = 0
          errtext = config_text.split(/\n/).map { |l| "#{linei += 1}: #{l}" }.join("\n")
          Rails.logger.warn e
          Rails.logger.warn errtext
          if Rails.env.test? || Rails.env.development?
            puts e
            puts errtext
          end

          bt = e.backtrace + [errtext]
          raise e, "#{e.message} -- see end of stacktrace for failed configuration YAML", bt
        end
      else
        res = {}
      end
      res.deep_symbolize_keys!

      set_defaults config_obj, res

      opt_default = res.delete(:_default)

      config_obj.configurations = res.delete(:_configurations)
      config_obj.table_comments = res.delete(:_comments)
      config_obj.db_columns = res.delete(:_db_columns)
      config_obj.data_dictionary = res.delete(:_data_dictionary)
      config_obj.options_constants = res.delete(:_constants)

      # Only run through additional processing of comments if the
      # configuration was just saved
      if config_obj.saved_changes? || force_all
        handle_table_comments config_obj, res
      elsif config_obj.table_comments
        config_obj.table_comments[:original_fields] = config_obj.table_comments[:fields]
      end

      res.delete_if { |k, _v| k.to_s.start_with? '_definitions' }

      res.each do |name, value|
        # If defined, use the optional _default entry as the basis for all individual options,
        # allowing for a definable set of default values

        value = opt_default.merge(value) if opt_default && !name.in?(%i[primary blank_log])

        i = new name, value, config_obj
        configs << i
      end

      configs
    rescue FphsException => e
      raise FphsException, e
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

      new_tc = config_obj.name.underscore.humanize.captionize
      if ts.blank? # ts != new_tc
        # Set a default table comment value
        config_obj.table_comments[:table] = "#{config_obj.class.name.humanize}: #{new_tc}"
      end

      default = res[:default]
      return unless default

      new_tc = default[:label] || config_obj.name.underscore.humanize.captionize
      if ts.blank? # ts != new_tc
        # Set the table comment from the config label if it was not set
        config_obj.table_comments[:table] = "#{config_obj.class.name.humanize}: #{new_tc}"
      end

      # Get a hash of field comments to update
      fs = tc[:fields] || {}
      original_fs = fs.dup

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
      ca = ConditionalActions.new(ci, obj, return_failures:)
      ca.calc_action_if
    end

    def self.set_defaults(config_obj, all_options = {}); end

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
  end
end
