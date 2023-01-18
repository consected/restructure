# frozen_string_literal: true

module Dynamic
  module DefHandler
    extend ActiveSupport::Concern

    included do
      after_save :force_option_config_parse
      attr_accessor :configurations, :data_dictionary, :options_constants
    end

    class_methods do
      # Attribute holding option configs text
      # This is the default and may be overridden in definition classes
      def option_configs_attr
        :options
      end

      # String naming the namespace prefix for the implementation
      # Must be overriden
      def implementation_prefix
        raise FphsException, "implementation_prefix not overridden for class: #{name}"
      end

      # A list of model names for models that have been generated and are ready to be used
      def model_names
        @model_names ||= []
      end

      # A list of model names for models that have been generated and are ready to be used
      def model_name_strings
        model_names.map(&:to_s)
      end

      # A list of models that have been generated and are ready to be used
      def models
        @models ||= {}
      end

      # If necessary, ensure other dynamic implementations have been loaded before we attempt to create this one
      def preload
        nil
      end

      #
      # Class that implements options for this dynamic type.
      # Inherits from ExtraOptions.
      # Must be overridden by specific dynamic type classes
      # @return [ExtraOptions]
      def options_provider
        nil
      end

      #
      # Should the options provider allow empty / nil options to be defined.
      # If true, it will set up an empty configuration instance to use by default
      # Otherwise, the option config type will return nil if not defined
      # @return [Boolean]
      def allow_empty_options
        true
      end

      # Get the list of model defintions based on them being available in
      # the active app types.
      # This means that we drop out configurations for app types that are disabled
      # or are not included in the OnlyLoadAppTypes setting.
      # This is typically used to improve load times and ensure we only generate
      # templates for models that will actually be used.
      # @return [ActiveRecord::Relation] scoped results
      def active_model_configurations
        # return @active_model_configurations if @active_model_configurations

        olat = Admin::AppType.active_app_types

        # List of names that the associated_* items have already returned
        # to avoid building huge lists of repetitive joined queries
        got_names = []

        if olat&.present?
          qs = []
          olat.each do |app_type|
            resnames = []
            # Compare against string class names, to avoid autoload errors
            case name
            when 'ActivityLog'
              res = app_type.associated_activity_logs(not_resource_names: got_names)
              resnames = app_type.associated_activity_log_names
            when 'DynamicModel'
              res = app_type.associated_dynamic_models(valid_resources_only: false, not_resource_names: got_names)
              resnames = app_type.associated_dynamic_model_names
            when 'ExternalIdentifier'
              res = app_type.associated_external_identifiers(not_resource_names: got_names)
              resnames = app_type.associated_external_identifier_names
            end
            if resnames.present? && (resnames - got_names).present?
              qs << res.reorder('').to_sql
              got_names |= resnames
            end
          end
          if qs.present?
            unions = qs.join("\nUNION\n")
            dma = from(Arel.sql("(#{unions}) AS #{table_name}"))
          else
            dma = where(id: nil)
          end
        else
          dma = active
        end
        @active_model_configurations = dma
      end

      def reset_active_model_configurations!
        @active_model_configurations = nil
      end

      # Get all the resource names for options configs in all active dynamic definitions
      # Used by user filestore filters
      # @param [Proc] an optional block may be passed to allow filtering based
      #   on values in the option config for each entry
      #   for example:
      #      all_option_configs_resource_names {|e| e && e.references && e.references[:nfs_store__manage__container]}
      # @return [Array] array of string names
      def all_option_configs_resource_names(&block)
        res = []

        @all_option_configs_resource_names ||= active_model_configurations.map(&:option_configs)

        @all_option_configs_resource_names.each do |a|
          elts = if block_given?
                   a.select(&block)
                 else
                   a
                 end
          res += elts.map(&:resource_name)
        end

        res
      end

      # Get all the resource names for options configs in all active dynamic definitions
      # grouped by the item category + name.
      # Used by user access control definitions
      # @param [Proc] an optional block may be passed to allow filtering based
      #   on values in the option config for each entry
      #   for example:
      #      all_option_configs_resource_names {|e| e && e.references && e.references[:nfs_store__manage__container]}
      # @return [Array] array of string names
      def all_option_configs_grouped_resources(&block)
        res = {}

        @all_option_configs_resource_names ||= active_model_configurations.map(&:option_configs)

        @all_option_configs_resource_names.each do |a|
          elts = if block_given?
                   a.select(&block)
                 else
                   a
                 end

          group_name = [a.first.def_item.category, a.first.def_item.name].select(&:present?).join(': ')
          res[group_name] = elts.map { |r| [r.resource_name, r.label] }.to_h
        end

        res
      end

      # Force the memoized version of #all_option_configs_resource_names to be reset so it
      # will be regenerated next time
      def reset_all_option_configs_resource_names!
        @all_option_configs_resource_names = nil
      end

      #
      # The list of defined and usable activity log implementation classes.
      # By default only return classes that are usable. Unusable classes may be due to
      # the underlying table not being within the defined schema search path.
      # @param [true] only_usable
      def implementation_classes(only_usable: true)
        @implementation_classes = active_model_configurations.map do |dm|
          if only_usable
            klass = dm.prefix_class
            next unless dm.implementation_class_defined?(klass, fail_without_exception: true)
          end

          dm.implementation_class
        end

        @implementation_classes.compact!
        @implementation_classes
      end

      # List of item types that can be used to define Classification::GeneralSelection drop downs
      # This does not represent the actual item types that are valid for selection
      # when defining a new definition record, which
      # is in fact provided by self.use_with_class_names
      def item_types(refresh: false)
        cname = "#{name}.item_types"
        Rails.cache.delete(cname) if refresh

        Rails.cache.fetch(cname) do
          list = []
          implementation_classes.each do |imp_class|
            list += imp_class.attribute_names
                             .select { |a| Classification::GeneralSelection.use_with_attribute?(a) }
                             .map do |a|
              mn = imp_class.model_name.to_s.ns_underscore
              mn = mn.pluralize unless imp_class.respond_to?(:is_activity_log)
              "#{mn}_#{a}".to_sym
            end
          end

          list
        end
      end

      # Allow new models to be added to the nested attributes dynamically by models as they are configured
      def add_nested_attribute(attrib)
        @master_nested_attrib ||= Master::MasterNestedAttribs.dup
        @master_nested_attrib << attrib
        Master.accepts_nested_attributes_for(*@master_nested_attrib)
      end

      #
      # Get the timestamp for the latest definition stored in the DB.
      # @return [DateTime]
      def latest_stored_update
        active_model_configurations
          .select(:updated_at)
          .reorder('')
          .order('updated_at desc nulls last')
          .limit(1)
          .pluck(:updated_at)
          .first
      end

      #
      # Does the persisted latest updated definition match the memoized update?
      # Returns nil if not previously memoized, otherwise true or false.
      # @return [true | false | nil]
      def up_to_date?
        lu = latest_stored_update

        if !lu && !@prev_latest_update
          # They match if both nil
          true
        elsif lu && @prev_latest_update && (lu - @prev_latest_update).abs < 2
          # Consider them a match if they are within 2 seconds of one another,
          # accounting for the difference between Rails and DB times
          true
        elsif @prev_latest_update.nil?
          # The remembered value was nil, so let the caller know this
          self.prev_latest_update = lu
          nil
        else
          # There was no match
          self.prev_latest_update = lu
          false
        end
      end

      #
      # Remember the latest updated at timestamp
      def prev_latest_update=(updated_at)
        return if @prev_latest_update && updated_at && updated_at <= @prev_latest_update

        @prev_latest_update = updated_at
      end

      # End of class_methods
    end

    def secondary_key
      return @secondary_key if @secondary_key_set

      @secondary_key_set = true
      # Parse option configs if necessary
      option_configs
      @secondary_key = configurations && configurations[:secondary_key]
    end

    def use_current_version
      return @use_current_version if @use_current_version_set

      @use_current_version_set = true
      # Parse option configs if necessary
      option_configs
      @use_current_version = configurations && configurations[:use_current_version]
    end

    def prevent_migrations
      return @prevent_migrations if @prevent_migrations_set

      @prevent_migrations_set = true
      # Parse option configs if necessary
      option_configs
      @prevent_migrations = configurations && configurations[:prevent_migrations]
    end

    # Return result based on the current
    # list of model defintions based on them being available in
    # the active app types.
    def active_model_configuration?
      self.class.active_model_configurations.include? self
    end

    # At this time dynamic models only use one config definition, under the 'default' key
    # Simplify access to the default options configuration
    def default_options
      option_type_config_for :default
    end

    #
    # Get the definition's stored option config text from its appropriate attribute
    # Return nil if there is option_configs_attr is nil
    # @param [String | Symbol] alt_option_config_attr - specify an alternative attribute
    #   containing the options config. Used when multiple options are available within a single model.
    # @return [String | nil]
    def options_text(alt_option_config_attr = nil)
      alt_option_config_attr ||= self.class.option_configs_attr
      return unless alt_option_config_attr

      send(alt_option_config_attr).dup
    end

    #
    # Parse option configs
    # @param [Boolean] force forces the memoized version to be updated
    # @param [<Type>] raise_bad_configs ensures bad configurations are checked and
    #    exceptions raised to halt execution
    # @return [Array] configurations
    def option_configs(force: false, raise_bad_configs: false)
      return if disabled?

      @option_configs = nil if force
      @option_configs ||= self.class.options_provider.parse_config(self, force)
      self.class.options_provider.raise_bad_configs @option_configs if raise_bad_configs
      @option_configs
    end

    #
    # Array of option config names (Symbols)
    # @return [Array{Symbol}]
    def option_configs_names
      option_configs&.map(&:name)
    end

    #
    # The option config for a specific named type
    # @param [Symbol] name to match
    # @param [Symbol] result_if_empty optionally selects the result to return if there is no matching name
    #    The options are:
    #      - :default - the default if not specified, generates an empty configuration with the name :default
    #      - :first_config - get the first item in the option_configs array
    #      - generates an empty configuration with the name specified in result_if_empty
    # @return [Class] options provider instance
    def option_type_config_for(name, result_if_empty: :default)
      return unless option_configs

      res = option_configs.find { |s| s.name == name.to_s.underscore.to_sym }

      if !res && self.class.allow_empty_options
        res = if result_if_empty == :first_config
                option_configs.first
              else
                self.class.options_provider.new(result_if_empty, {}, self)
              end

      end
      res
    end

    #
    # Validate that the option configs parse correctly
    # @return [Boolean]
    def option_configs_valid?
      self.class.options_provider.configs_valid?(self)
    end

    #
    # Simply parse option configs, forcing the memoized version to be updated
    # @return [Array] parsed configs
    def force_option_config_parse
      return if disabled?

      @secondary_key_set = false
      @secondary_key = nil
      @use_current_version_set = false
      @use_current_version = nil

      option_configs force: true, raise_bad_configs: true
    end

    # This needs to be overridden in each provider to allow consistency of calculating model names for implementations
    # Non-namespaced model definition name
    # @return [String]
    def implementation_model_name
      nil
    end

    # Non-namespaced model definition name
    def model_class_name
      implementation_model_name.ns_camelize
    end

    # Return the model class for this definition
    def model_class
      self.class.models[implementation_model_name]
    end

    # The name of the association within the Master class
    def model_association_name
      full_implementation_class_name.pluralize.ns_underscore.to_sym
    end

    # Full namespaced item type name, underscored with double underscores
    # If there is no prefix then this matches the simple model name
    def full_item_type_name
      prefix = ''
      prefix = "#{self.class.implementation_prefix.ns_underscore}__" if self.class.implementation_prefix.present?

      "#{prefix}#{implementation_model_name}"
    end

    # Full namespaced item types (pluralized) name, underscored with double underscores
    def full_item_types_name
      full_item_type_name.pluralize
    end

    # Hyphenated name, typically used in HTML markup for referencing target blocks and panels
    def hyphenated_name
      implementation_model_name.ns_hyphenate
    end

    # Absolute namespaced class name for the model
    def full_implementation_class_name
      full_item_type_name.ns_camelize
    end

    # Absolute namespaced class name for the matching controller
    def full_implementation_controller_name
      "#{model_class_name.pluralize}Controller"
    end

    # The model class that can be instantiated
    def implementation_class
      full_implementation_class_name.ns_constantize
    rescue StandardError => e
      msg = "Failed to get the implementation_class for #{full_implementation_class_name}: #{e}"
      Rails.logger.warn msg
      Rails.logger.warn e.backtrace.join("\n")
      raise e, msg
    end

    # Allow definitions to not be associated with a master record,
    # but only if we allow a foreign key name to be specified and it isn't
    # In reality, only DynamicModel classes can do this
    def implementation_no_master_association
      defined?(foreign_key_name) && foreign_key_name.blank?
    end

    def prefix_class
      klass = Object
      klass = "::#{self.class.implementation_prefix}".constantize if self.class.implementation_prefix.present?
      klass
    end

    #
    # Returns :table or :view if the underlying database object is a table or a view.
    # Returns nil if no underlying object is found
    # @return [Symbol | nil]
    def table_or_view
      return unless Admin::MigrationGenerator.table_or_view_exists? table_name

      return :table if Admin::MigrationGenerator.table_exists? table_name

      :view
    end
  end
end
