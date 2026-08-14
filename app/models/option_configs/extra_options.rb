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
    # Top-level YAML keys in libraries that must be renamed to avoid collisions when injected
    LibraryKeyRenamePatterns = %w[_definitions _default _constants _configurations].freeze
    ValidFieldConfigs = %i[db_configs field_options labels caption_before dialog_before show_if].freeze

    # Registry of configuration classes, in the order they must be initialized.
    # Each entry maps a key (used in config_instances) to the config class.
    # The order mirrors the original clean_... method call sequence.
    def self.config_class_registry
      {
        fields: ExtraOptionConfigs::Fields,
        field_configs: ExtraOptionConfigs::FieldConfigs,
        label: ExtraOptionConfigs::Label,
        caption_before: ExtraOptionConfigs::CaptionBefore,
        dialog_before: ExtraOptionConfigs::DialogBefore,
        labels: ExtraOptionConfigs::Labels,
        show_if: ExtraOptionConfigs::ShowIf,
        save_action: ExtraOptionConfigs::SaveAction,
        view_options: ExtraOptionConfigs::ViewOptions,
        db_configs: ExtraOptionConfigs::DbConfigs,
        creatable_if: ExtraOptionConfigs::CreatableIf,
        editable_if: ExtraOptionConfigs::EditableIf,
        showable_if: ExtraOptionConfigs::ShowableIf,
        valid_if: ExtraOptionConfigs::ValidIf,
        filestore: ExtraOptionConfigs::Filestore,
        field_options: ExtraOptionConfigs::FieldOptions,
        embed_config: ExtraOptionConfigs::Embed,
        references_config: ExtraOptionConfigs::References,
        save_trigger: ExtraOptionConfigs::SaveTrigger,
        batch_trigger: ExtraOptionConfigs::BatchTrigger,
        config_trigger: ExtraOptionConfigs::ConfigTrigger,
        preset_fields: ExtraOptionConfigs::PresetFields,
        set_variables: ExtraOptionConfigs::SetVariable
      }
    end

    def self.base_key_attributes
      %i[
        name config_obj resource_name resource_item_name add_reference_if
        button_label orig_config show_if_condition_strings raw_field_configs
        references embed
      ]
    end

    def self.config_class_attributes
      config_class_registry.keys
    end

    def self.add_key_attributes
      []
    end

    def self.key_attributes
      base_key_attributes + config_class_attributes + add_key_attributes
    end

    def self.editable_attributes
      key_attributes - %i[name config_obj resource_name resource_item_name] + [:label]
    end

    attr_accessor(*key_attributes, :def_item, :config_instances)

    #
    # Initialize a named option configuration, which may form one of many in a dynamic definition
    # @param [String] name - the name of the configuration
    # @param [Hash] config - the parsed options text for this individual configuration
    # @param [ActiveRecord::Base] config_obj - the definition record storing this dynamic definition & options
    def initialize(name, config, config_obj)
      super()
      @name = name
      @orig_config = config
      @config_instances = {}

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

        # Delegate to configuration classes in order
        self.class.config_class_registry.each do |key, config_class|
          if config_class < ExtraOptionConfigs::BaseConfiguration
            # Determine where to read raw input (source_attribute or registry key)
            source_key = config_class.source_attribute || key
            raw = send(source_key)
            raw = config_class.prepare_config(raw, self) if config_class.respond_to?(:prepare_config)
            instance = config_class.new(raw)

            if config_class.source_attribute
              # source_attribute pattern: enriched value → source attr, instance → registry key
              direct_attr = config_class.option_types[:direct]&.first || source_key
              send("#{source_key}=", instance.send(direct_attr))
              send("#{key}=", instance)
            elsif config_class.store_processed_value?
              # Collect errors/warnings before discarding the instance
              collect_instance_errors(instance, registry_key: key)
              # Value-preprocessor class: store the processed value, not the object
              direct_attr = config_class.option_types[:direct]&.first || key
              send("#{key}=", instance.send(direct_attr))
            else
              # Rich object class: store the BaseConfiguration instance
              send("#{key}=", instance)
            end
          else
            # ConfigBase pattern: initialize with parent reference, apply back
            ci = config_class.new(self)
            ci.apply_to_parent!
            @config_instances[key] = ci
          end
        end

        # Collect config errors/warnings from field-keyed config instances
        collect_field_config_errors

        # Handle config_obj mutation for db_configs (extracted from clean_db_configs_def).
        # Guard against nil db_columns: option_type_config_for may instantiate
        # ExtraOptions directly with config_obj where db_columns has not been
        # assigned by parse_config (e.g. boot-time synthesized empty defaults).
        if config_obj.respond_to?(:db_columns) && config_obj.db_columns && config_obj.db_columns.blank?
          config_obj.db_columns.merge!(db_configs.symbolize_keys)
        end

        # raw_field_configs is saved inside FieldConfigs.prepare_config (before standalone cleaning)
        # Now merge cleaned standalone definitions into field_configs
        validate_missing_general_selection_configs
        add_field_configs_from_standalone_defs
      rescue StandardError => e
        Rails.logger.warn "Failed to initialize ExtraOptions for #{@name}: #{e}"
        Rails.logger.warn e.short_string_backtrace
        raise FphsOptionsGeneralError, "Failed to initialize ExtraOptions for #{@name}: #{e}", e.backtrace
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

    # Re-run reference resolution on the current +references+ attribute.
    #
    # Normalizes, resolves, and enriches references using the References config class,
    # updating +self.references+ in place. Unresolved references outside of an
    # app-type import are removed from the hash and a +:warn+ notice is recorded in
    # +config_warnings+. During an import, unresolved references are left untouched
    # and silent (forward references to not-yet-imported definitions are expected).
    #
    # This is the public post-initialization API for cases where +references+ is
    # assigned directly (e.g. after runtime config changes or in tests).
    def clean_references_def
      return unless references

      new_ref = ExtraOptionConfigs::References.prepare_config(references, self)
      self.references = new_ref

      bad_refs = new_ref&.delete(:_bad_references)
      return unless bad_refs.present?

      bad_refs.each do |mn|
        failed_config(:references, "unresolved reference '#{mn}' - no model class could be found", level: :warn)
      end
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

    # For dynamic model definitions, fields that are selection-like by naming
    # convention (for example source, rank, select_*) must provide at least one
    # selection source. This can come from persisted general selections or
    # explicit field_options.edit_as overrides.
    def validate_missing_general_selection_configs
      return unless config_obj.is_a?(DynamicModel)

      selection_fields = Array(fields).select { |f| Classification::GeneralSelection.use_with_attribute?(f.to_s) }
      return if selection_fields.empty?

      selection_fields.each do |field_name|
        # Fields that source their own options at runtime (records from a master
        # association, or users holding a role) never need a general selection config.
        next if Classification::SelectionOptionsHandler.self_sourcing_field?(field_name)
        next if general_selection_present_for_dynamic_model_field?(field_name)
        next if field_has_selection_override?(field_name)

        failed_config(:field_options, "missing general selection config for field #{field_name}")
      end
    end

    def general_selection_present_for_dynamic_model_field?(field_name)
      item_type_prefixes = [
        "dynamic_model__#{config_obj.table_name}",
        "dynamic_model__#{config_obj.table_name.singularize}",
        "dynamic_model__#{config_obj.table_name.pluralize}"
      ].uniq

      item_type_names = item_type_prefixes.map { |prefix| "#{prefix}_#{field_name}" }
      Classification::GeneralSelection.where(item_type: item_type_names).exists?
    end

    def field_has_selection_override?(field_name)
      # Fields using these naming patterns have implicit selection mechanisms
      # (role-based user lists or record-from-table lookups) that don't require
      # a GeneralSelection entry.
      return true if field_name.to_s.start_with?('select_record_from_', 'select_user_with_role_')

      fopts = field_options[field_name.to_sym] if field_options.respond_to?(:[])
      return false unless fopts.respond_to?(:dig)

      edit_as = fopts[:edit_as]
      return false unless edit_as.is_a?(Hash)

      edit_as[:alt_options].present? || edit_as[:general_selection].present? || edit_as[:field_type].present?
    end

    # Collect config errors and warnings from a single BaseConfiguration instance.
    # Used during registry initialization to capture errors before the instance
    # may be discarded (for store_processed_value? classes).
    # @param instance [BaseConfiguration] the config instance
    # @param registry_key [Symbol] the config_class_registry key for this instance
    def collect_instance_errors(instance, registry_key: nil)
      return unless instance.respond_to?(:config_errors)

      if instance.config_errors.present?
        config_errors.concat(instance.config_errors.each { |e| enrich_config_notice(e, registry_key:) })
      end
      return unless instance.config_warnings.present?

      config_warnings.concat(instance.config_warnings.each { |e| enrich_config_notice(e, registry_key:) })
    end

    # Collect config errors and warnings from field-keyed config instances
    # (those inheriting ExtraOptionConfigs::BaseConfiguration) into the
    # parent ExtraOptions config_errors/config_warnings arrays.
    # Only collects from instances that were not already collected via
    # collect_instance_errors during initialization (i.e. store_processed_value?
    # classes that were discarded).
    def collect_field_config_errors
      self.class.config_class_registry.each do |key, config_class|
        next unless config_class < ExtraOptionConfigs::BaseConfiguration

        config_instance = send(key)
        next unless config_instance&.respond_to?(:config_errors)

        if config_instance.config_errors.present?
          config_errors.concat(config_instance.config_errors.each { |e| enrich_config_notice(e, registry_key: key) })
        end
        next unless config_instance.config_warnings.present?

        config_warnings.concat(config_instance.config_warnings.each do |e|
          enrich_config_notice(e, registry_key: key)
        end)
      end
    end

    # Enrich a config notice hash from a BaseConfiguration instance with
    # the parent ExtraOptions context fields expected by the admin panel template.
    # Mutates the hash in place, filling in missing keys.
    #
    # The template title renders: "{resource_name} - {name} - {type}"
    # so :type should identify the config section (and field) for admin clarity,
    # e.g. "caption_before > no_field". The :message should contain just the
    # error detail without redundant context.
    #
    # :config_def is built as a YAML-friendly hash mirroring the config path,
    # e.g. { caption_before: { no_field: { "do this" => true } } } so the
    # admin panel preview shows exactly which YAML structure is problematic.
    #
    # @param notice [Hash] the config error/warning hash to enrich
    # @param registry_key [Symbol, nil] the config_class_registry key (e.g. :caption_before)
    def enrich_config_notice(notice, registry_key: nil)
      notice[:name] ||= name
      notice[:resource_name] ||= resource_name
      notice[:config_class] ||= config_obj&.class&.name
      notice[:config_object] ||= config_obj
      notice[:config_resource_name] ||= config_obj&.class&.resource_name if config_obj

      # Set :type to the config section path so the template heading identifies
      # the source. field_name is the YAML key within the section (e.g. :no_field).
      field_name = notice.delete(:field_name)
      field_config = notice.delete(:field_config)
      if registry_key
        config_class = self.class.config_class_registry[registry_key]
        section_key = config_class&.source_attribute || registry_key
        section = section_key.to_s
        section = "#{section} > #{field_name}" if field_name
        notice[:type] = section

        # Build config_def as a string-keyed nested hash showing the YAML path.
        # Deep-stringify keys so the template renders clean YAML regardless of
        # which YAML method is used.
        unless notice[:config_def].present?
          cd = if field_name
                 { section_key => { field_name => field_config } }
               elsif field_config
                 { section_key => field_config }
               else
                 {}
               end
          notice[:config_def] = cd.deep_stringify_keys
        end
      end
      notice[:config_def] ||= {}
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
      config_obj.configurations = ExtraOptionConfigs::Configurations.new(
        options_based_on_keys_stating_with('_configurations', loaded_config)
      )

      set_defaults config_obj, loaded_config

      config_obj.table_comments = ExtraOptionConfigs::Comments.new(loaded_config.delete(:_comments) || {})
      config_obj.db_columns = ExtraOptionConfigs::DbColumns.new(loaded_config.delete(:_db_columns) || {})
      config_obj.data_dictionary = ExtraOptionConfigs::DataDictionaryConfig.new(loaded_config.delete(:_data_dictionary) || {})
      config_obj.options_constants = ExtraOptionConfigs::Constants.new(options_based_on_keys_stating_with('_constants',
                                                                                                          loaded_config) || {})

      # Definitions '_definitions...' are only used by YAML for the definition of anchors
      # and so will already by incorporated into the relevant configurations.
      loaded_config.delete_if { |k, _v| k.to_s.start_with? '_definitions' }

      configs = handle_defaults_merges_overrides(config_obj, loaded_config, raise_underscore_keys: true)
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

      # If the config_obj is a versioned definition (from history), pass its timestamp
      # so that config libraries are resolved at the same point in time.
      # Skip versioned library resolution when:
      #   - Settings::DisableVDef is true (versioning disabled globally, e.g. development)
      #   - use_current_version is set on the definition (always uses latest)
      version_at = nil
      uses_current_definition_version = if config_obj.respond_to?(:uses_current_definition_version?)
                                          config_obj.uses_current_definition_version?
                                        else
                                          Settings::DisableVDef ||
                                            (config_obj.respond_to?(:use_current_version) && config_obj.use_current_version)
                                        end

      if !uses_current_definition_version &&
         config_obj.respond_to?(:def_version) && config_obj.def_version.present?
        version_at = config_obj.updated_at || config_obj.created_at
      end

      config_text = include_libraries(config_text, version_at:)
      config_text.gsub(/^---.*\n/, '')
    end

    #
    # Parse the options text then dump it back to clean YAML with anchors resolved
    # @param [ActiveRecord::Base] config_obj - dynamic definition record
    # @return [String | nil] clean YAML string with anchors resolved, or nil if blank
    def self.parsed_options_text(config_obj)
      loaded_config = parse_options_text(config_obj)
      return nil unless loaded_config.is_a?(Hash) && loaded_config.present?

      # Remove internal keys that are not part of the option type configurations,
      # matching the cleanup in parse_config.
      # _comments, _db_columns, _data_dictionary are deleted directly.
      # _definitions (and _definitions__xxx from libraries) are deleted by prefix.
      # _constants and _configurations (and their library-prefixed variants) are consumed
      #   by options_based_on_keys_stating_with — return values discarded as they are not
      #   needed here; the calls are made only to strip those keys from loaded_config.
      # Keys like _default, _merge_default, _merge_override and _override are retained
      #   for handle_defaults_merges_overrides below.
      %i[_comments _db_columns _data_dictionary].each { |k| loaded_config.delete(k) }
      loaded_config.delete_if { |k, _v| k.to_s.start_with? '_definitions' }
      options_based_on_keys_stating_with('_configurations', loaded_config)
      options_based_on_keys_stating_with('_constants', loaded_config)

      hash_results = {}
      handle_defaults_merges_overrides(config_obj, loaded_config, hash_results:)
      return nil if hash_results.blank?

      String.yaml_dump(hash_results)
    end

    # Top-level configuration sections that describe the underlying database
    # table (field comments, column types and the data dictionary) rather than
    # the runtime option type configurations. They are consumed only by admin
    # and migration flows and are deleted from the loaded config before any
    # runtime use (see parse_config). If a previous corruption (issue #676)
    # damaged one of these sections, the whole YAML document fails to parse even
    # though the runtime configuration is intact.
    DbDefinitionOnlySections = %w[_comments _db_columns _data_dictionary].freeze

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
        rescue Psych::Exception => e
          # The DB-definition-only sections are not required for runtime usage.
          # Strip them and retry so a corruption confined to (or removable with)
          # those sections cannot break rendering for an otherwise-valid runtime
          # configuration. Genuine runtime config errors still raise below.
          recovered = recover_runtime_config(config_text, config_obj, e)
          return recovered.deep_symbolize_keys! unless recovered.nil?

          linei = 0
          errtext = config_text.split("\n").map { |l| "#{linei += 1}: #{l}" }.join("\n")
          Rails.logger.warn e
          Rails.logger.warn errtext
          if Rails.env.test? || Rails.env.development?
            $stderr.puts e
            $stderr.puts errtext
          end
          Rails.logger.warn 'Failed configuration YAML at:'
          Rails.logger.warn(ExceptionExtensions.short_string_backtrace(caller))
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
    # Attempt to recover a parseable runtime configuration from options text that
    # failed to load, by removing the DB-definition-only sections
    # (_comments, _db_columns, _data_dictionary). These describe the database
    # table, not the runtime configuration, and are discarded before runtime use.
    # @param [String] config_text - the full prepared options text that failed to parse
    # @param [ActiveRecord::Base] config_obj - dynamic definition record (for logging)
    # @param [Exception] original_error - the original parse failure (for logging)
    # @return [Hash, nil] the recovered config hash, or nil if recovery was not possible
    def self.recover_runtime_config(config_text, config_obj, original_error)
      stripped = strip_db_definition_sections(config_text)
      return nil if stripped == config_text

      recovered = YAML.safe_load(stripped, permitted_classes: [], permitted_symbols: [], aliases: true)
      return nil unless recovered.is_a?(Hash)

      Rails.logger.warn(
        "Recovered runtime configuration for #{config_obj} by ignoring corrupt DB-definition sections " \
        "(#{original_error.class.name}: #{original_error.message}). The stored options need to be repaired."
      )
      recovered
    rescue Psych::Exception
      # The runtime configuration is genuinely broken (not just the DB-definition
      # sections), so recovery is not possible. Let the caller raise the original error.
      nil
    end

    #
    # Remove the DB-definition-only top-level sections from options text using
    # line-based scanning. A section starts at a line whose first character is one
    # of the section keys followed by ':' (column 0) and continues until the next
    # line that begins with a non-whitespace character (the next top-level key).
    # Line scanning is used (rather than YAML parsing) precisely because the text
    # may be malformed.
    # @param [String] config_text
    # @return [String] config_text with the DB-definition sections removed
    def self.strip_db_definition_sections(config_text)
      section_start = /\A(#{DbDefinitionOnlySections.join('|')}):/
      skipping = false

      config_text.lines.reject do |line|
        if line.match?(section_start)
          skipping = true
        elsif skipping && line.match?(/\A\S/)
          skipping = false
        end
        skipping
      end.join
    end

    #
    # Create a final set of configurations for each of the main option types,
    # incorporating _default..., _merge_... and _override entries
    # @param [ActiveRecord::Base] config_obj dynamic definition record
    # @param [Hash] loaded_config configuration hash
    # @return [Array] configuration instances
    def self.handle_defaults_merges_overrides(config_obj, loaded_config, hash_results: {}, raise_underscore_keys: nil)
      configs = []

      # Handle any entry starting with "_default"
      opt_default = options_based_on_keys_stating_with('_default', loaded_config)

      opt_merge_default = loaded_config.delete(:_merge_default)
      opt_merge_override = loaded_config.delete(:_merge_override)
      opt_override = loaded_config.delete(:_override)

      # All valid underscore keys have now been consumed. Any remaining key starting with '_'
      # is a config error — e.g. _definition_... instead of _definitions_... (#1163).
      if raise_underscore_keys
        unexpected_keys = loaded_config.keys.select { |k| k.to_s.start_with?('_') }
        if unexpected_keys.any?
          suggestion = if unexpected_keys.any? do |k|
            k.to_s.start_with?('_definition_')
          end
                         ' (did you mean _definitions_?)'
                       else
                         ''
                       end
          raise FphsOptionsParseError,
                "Configuration contains unexpected underscore-prefixed keys: #{unexpected_keys.join(', ')}#{suggestion}"
        end
      end

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
        hash_results[name] = value
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

      ca = ConditionalActions.new(normalize_condition_config(ci), obj)
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

      config = normalize_condition_config(send(key))
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

      ci = valid_if[:"on_#{action_type}"]
      Rails.logger.debug "Checking calc_valid_if on #{obj} with #{ci}"
      ca = ConditionalActions.new(normalize_condition_config(ci), obj, return_failures:)
      ca.calc_action_if
    rescue StandardError => e
      Rails.logger.error "Error occurred while checking calc_valid_if with #{action_type} on #{obj} user #{obj.current_user}: #{e}"
      Rails.logger.error e.short_string_backtrace
      raise FphsCalcConditionError,
            "Error occurred while checking calc_valid_if condition on #{action_type} - user #{obj.current_user} - time #{Time.now}: #{e}"
    end

    def self.set_defaults(config_obj, all_options = {}); end

    private

    def normalize_condition_config(config)
      return config if config.is_a?(Hash) || config.nil?
      return config.to_hash if config.respond_to?(:to_hash)
      return config.to_h if config.respond_to?(:to_h)

      config
    end

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
        content = standard_option_defs_yaml(type)
        next unless content

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

      defs_yaml = standard_option_defs_yaml(force_type)
      return content_to_update unless defs_yaml

      "# @#{force_type}_standard_definitions_start\n#{defs_yaml}\n# @#{force_type}_standard_definitions_end\n#{content_to_update}\n"
    end

    #
    # Read (and memoize) the contents of a standard_option_defs.yaml file for the given type.
    # These files are static application code, not admin-editable data, so their content cannot
    # change without a deploy/restart - memoizing avoids re-reading the same file from disk on
    # every single option_configs parse (previously once per dynamic definition, e.g. on the
    # admin index page - see issue #1354).
    # @param [String] force_type
    # @return [String, nil] file contents, or nil if the file doesn't exist
    def self.standard_option_defs_yaml(force_type)
      @standard_option_defs_yaml ||= {}
      return @standard_option_defs_yaml[force_type] if @standard_option_defs_yaml.key?(force_type)

      path = Rails.root.join('app', 'models', 'admin', 'defs', "#{force_type}_standard_option_defs.yaml")
      @standard_option_defs_yaml[force_type] = File.exist?(path) ? File.read(path) : nil
    end

    #
    # Inject config libraries into the provided content.
    # When version_at is provided, resolves library content as it was at that point in time.
    # @param content_to_update [String] (will not be modified)
    # @param version_at [Time | nil] optional timestamp for resolving versioned library content
    # @return [String] updated content
    def self.include_libraries(content_to_update, version_at: nil)
      return unless content_to_update

      content_to_update = content_to_update.dup
      reg = LibraryMatchRegex
      # Track libraries already sourced so a cyclic or self-referencing library
      # (e.g. A -> B -> A, possible when resolving a historical library version
      # with version_at) cannot be expanded repeatedly. Without this guard the
      # while loop below grows the text without bound — exponentially when a
      # cycle reintroduces more than one directive, since gsub! replaces every
      # occurrence on each pass. See issue #676. This mirrors the cycle
      # protection already present in requested_libraries.
      seen = Set.new
      res = content_to_update.match reg

      while res
        category = res[1].strip
        name = res[2].strip
        key = [category, name]

        if seen.include?(key)
          # Already sourced: neutralise the repeated reference rather than
          # expanding it again. The replacement intentionally does not match
          # LibraryMatchRegex, so the loop makes progress and terminates.
          Rails.logger.warn "Skipped cyclic config library reference '#{category} #{name}' while including libraries"
          content_to_update.gsub!(res[0], "# @library_cycle_skipped #{category} #{name}")
          res = content_to_update.match reg
          next
        end
        seen.add(key)

        lib = if version_at
                Admin::ConfigLibrary.content_named_at(category, name, format: :yaml, at: version_at)
              else
                Admin::ConfigLibrary.content_named(category, name, format: :yaml)
              end
        lib = (lib || '').dup
        LibraryKeyRenamePatterns.each do |key_pattern|
          lib.gsub!(/^#{key_pattern}:.*/, "#{key_pattern}__#{category}_#{name}:")
        end
        lib = "# @sourced_library_start #{category} #{name}\n#{lib}\n# @sourced_library_end #{category} #{name}\n"
        content_to_update.gsub!(res[0], lib)
        res = content_to_update.match reg
      end

      content_to_update
    end

    #
    # Find referenced libraries into the provided content,
    # recursively resolving nested library references.
    # @param [String] content
    # @return [Array{Hash}] array of hashes {category:, name:}
    def self.requested_libraries(content)
      return [] if content.blank?

      reshashes = []
      seen = Set.new
      queue = [content.dup]
      reg = LibraryMatchRegex

      while (text = queue.shift)
        res = text.match reg
        while res
          category = res[1].strip
          name = res[2].strip
          key = [category, name]
          unless seen.include?(key)
            seen.add(key)
            reshashes << { category:, name: }
            begin
              lib_content = Admin::ConfigLibrary.content_named(category, name, format: :yaml)
              queue << lib_content.dup if lib_content.present?
            rescue FphsException
              # Library not found - skip nested resolution for this reference
            end
          end
          text = text.sub(res[0], '')
          res = text.match reg
        end
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
