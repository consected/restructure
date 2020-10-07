# frozen_string_literal: true

module DynamicModelDefHandler
  extend ActiveSupport::Concern

  included do
    attr_accessor :table_comments

    after_save :generate_model, if: -> { ready_to_generate? }
    after_save :check_implementation_class
    after_save :force_option_config_parse
    after_save :generate_migration, if: -> { !disabled }
    after_save :run_migration, if: -> { @do_migration }

    after_save :add_master_association, if: -> { @regenerate }
    after_save :add_user_access_controls, if: -> { @regenerate }

    after_commit :update_tracker_events, if: -> { @regenerate }
    after_commit :restart_server, if: -> { @regenerate }
    after_commit :other_regenerate_actions
  end

  class_methods do
    def implementation_prefix
      nil
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
    def active_model_configurations
      olat = Admin::AppType.active_app_types

      if olat && !olat.empty?
        qs = []
        olat.each do |app_type|
          # Compare against string class names, to avoid autoload errors
          if name == 'ActivityLog'
            qs << app_type.associated_activity_logs.reorder('').to_sql
          elsif name == 'DynamicModel'
            qs << app_type.associated_dynamic_models(valid_resources_only: false).reorder('').to_sql
          elsif name == 'ExternalIdentifier'
            qs << app_type.associated_external_identifiers.reorder('').to_sql
          end
        end
        unions = qs.join("\nUNION\n")
        dma = from("(#{unions}) AS #{table_name}")
      else
        dma = active
      end
      dma
    end

    #
    # Run through the configurations to implement them and make them available for use
    # Since ActivityLog types actually preload DynamicModel and ExternalIdentifier types
    # typically this is only called as ``::ActivityLog.define_models`
    def define_models
      preload

      begin
        dma = active_model_configurations

        logger.info "Generating models #{name} #{dma.length}"

        dma.each do |dm|
          dm.generate_model
          # Force the admin for cases that this is run outside of the admin console
          # It is expected that this is mostly when originally seeding the database
          dm.current_admin ||= dm.admin

          dm.update_tracker_events
        end
      rescue Exception => e
        Rails.logger.warn "Failed to generate models. Hopefully this is only during a migration. #{e.inspect}"
      end
    end

    def routes_reload
      return unless @regenerate

      Rails.application.reload_routes!
      Rails.application.routes_reloader.reload!
    end

    # Enable active configurations for the dynamic type
    # This checks that underlying tables are available, the implementation
    # class is defined, and then it adds associations to Master
    # Both log an put any errors to stdout, since this may run in a migration
    # and a log alone won't be visible to the end user
    # To ensure that the db migrations can run,
    # check for the existence of the appropriate admin table
    # before attempting to do anything. Otherwise Rake tasks fail and
    # the admin table can't be generated, preventing setup of the app.
    def enable_active_configurations
      if Admin::MigrationGenerator.table_exists? table_name
        active_model_configurations.each do |dm|
          klass = if dm.is_a? ExternalIdentifier
                    Object
                  else
                    dm.class.name.constantize
                  end

          if dm.ready_to_generate? && dm.implementation_class_defined?(klass, fail_without_exception: true)
            dm.add_master_association
          else
            msg = "Failed to enable #{dm} #{dm.id} #{dm.resource_name}. Table ready? #{dm.table_or_view_ready?}"
            puts msg
            Rails.logger.warn msg
          end
        end
      else
        msg = "Table doesn't exist yet: #{table_name}"
        puts msg
        Rails.logger.warn msg
      end
    end

    # Get all the resource names for options configs in all active dynamic definitions
    # Used by user access control definitions and filestore filters
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

    def reset_all_option_configs_resource_names!
      @all_option_configs_resource_names = nil
    end

    # The list of defined and usable activity log implementation classes
    def implementation_classes
      @implementation_classes = active_model_configurations.map(&:implementation_class)
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
                           .map { |a| "#{imp_class.model_name.to_s.ns_underscore.pluralize}_#{a}".to_sym }
        end

        list
      end
    end
  end

  def active_model_configuration?
    self.class.active_model_configurations.include? self
  end

  def default_options
    option_type_config_for :default
  end

  def option_configs(force: false, raise_bad_configs: false)
    return if disabled?

    @option_configs = nil if force
    @option_configs ||= self.class.options_provider.parse_config(self)
    self.class.options_provider.raise_bad_configs @option_configs if raise_bad_configs
    @option_configs
  end

  def option_configs_names
    option_configs.map(&:name)
  end

  def option_type_config_for(name, result_if_empty: nil)
    return unless option_configs

    res = option_configs.find { |s| s.name == name.to_s.underscore.to_sym }

    if !res && self.class.allow_empty_options
      res = if result_if_empty == :first_config
              option_configs.first
            else
              self.class.options_provider.new(:default, {}, self)
            end

    end
    res
  end

  def option_configs_valid?
    self.class.options_provider.configs_valid?(self)
  end

  def force_option_config_parse
    return if disabled?

    option_configs force: true, raise_bad_configs: true
  end

  #
  # Simple test to see if the controller associated with the implementation model is defined
  # @param [Module | Class] parent_class is the parent for the controller, to handle namespacing issues
  # @return [Boolean]
  def implementation_controller_defined?(parent_class = Module)
    return false unless full_implementation_controller_name

    # Check that the class is defined
    klass = parent_class.const_get(full_implementation_controller_name)
    res = klass.is_a?(Class)
    res
  rescue NameError
    false
  end

  # Is the implementation class for this configuration defined so that it
  # can be instantiated?
  # @param [Module | Class] parent_class
  # @param [Hash] opt options
  # @option opt [String] :class_name is an alternative class name within the
  #   parent class to test. This can be used to avoid namespacing issues
  # @option opt [Boolean] :fail_without_exception if true we return a Boolean rather than raising an exception
  # @return [Boolean] true if the class is defined, and false or a raised exception depending on the options
  def implementation_class_defined?(parent_class = Module, opt = {})
    icn = opt[:class_name] || full_implementation_class_name
    return false unless icn

    # Check that the class is defined
    klass = parent_class.const_get(icn)
    res = klass.is_a?(Class)

    return false unless res

    begin
      # Check if it can be instantiated correctly - if it can't, allow it to raise an exception
      # since this is seriously unexpected
      klass.new
    rescue Exception => e
      err = "Failed to instantiate the class #{icn} in parent #{parent_class}: #{e}"
      logger.warn err
      raise FphsException, err unless opt[:fail_without_exception]

      # By default, return false if an error occurred attempting the initialization.
      # In certain cases (for example, checking if a class exists so it can be removed), returning true if the
      # class is defined regardless of whether it can be initialized makes most sense. Provide an option to support this.
      opt[:fail_without_exception_newable_result]
    end
  rescue NameError => e
    logger.warn e
    false
  end

  def prevent_regenerate_model
    got_class = begin
                  full_implementation_class_name.constantize
                rescue StandardError
                  nil
                end
    got_class if got_class&.to_s&.start_with?(self.class.implementation_prefix)
  end

  # Is the definition ready for a class to be defined?
  # Is it enabled and does it have an underlying table?
  def ready_to_generate?
    !disabled && table_or_view_ready?
  end

  #
  # Check if the underlying database table exists
  # @return [boolean]
  def table_or_view_ready?
    Admin::MigrationGenerator.table_or_view_exists?(table_name)
  rescue StandardError => e
    @extra_error = e
    false
  end

  # This needs to be overridden in each provider to allow consistency of calculating model names for implementations
  # Non-namespaced model definition name
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
  end

  # Allow definitions to not be associated with a master record,
  # but only if we allow a foreign key name to be specified and it isn't
  # In reality, only DynamicModel classes can do this
  def implementation_no_master_association
    defined?(foreign_key_name) && foreign_key_name.blank?
  end

  # Tracker events are required for each dynamic class. It is the
  # responsibility of the individual definition classes to handle this
  def update_tracker_events
    raise 'DynamicModel configuration implementation must define update_tracker_events'
  end

  # After a regeneration, certain other cleanups may be required
  def other_regenerate_actions
    Rails.logger.info 'Refreshing item types'
    Classification::GeneralSelection.item_types refresh: true
  end

  # A list of model names and definitions is stored in the class so we can
  # quickly see what dynamic classes are available elsewhere
  # Add an item to this list
  def add_model_to_list(m)
    tn = implementation_model_name
    self.class.models[tn] = m
    logger.info "Added new model #{tn}"
    self.class.model_names << tn unless self.class.model_names.include? tn
  end

  # Remove an item from the list of available dynamic classes
  def remove_model_from_list
    tn = implementation_model_name
    logger.info "Removed disabled model #{tn}"
    self.class.models.delete(tn)
    self.class.model_names.delete(tn)
  end

  def remove_assoc_class(in_class_name)
    # Dump the old association
    assoc_ext_name = "#{in_class_name}#{model_class_name.pluralize}AssociationExtension"
    Object.send(:remove_const, assoc_ext_name) if implementation_class_defined?(Object)
  rescue StandardError => e
    logger.debug "Failed to remove #{assoc_ext_name} : #{e}"
    # puts "Failed to remove #{assoc_ext_name} : #{e}"
  end

  #
  # Create a user access control for the item with a template role, to
  # ensure that it is correctly exported from an app type, even
  # if no real end users or roles have been applied to it
  # The underlying call will update an existing user access control if it
  # already exists.
  # This is called by an after_save trigger, and may also be used in specs directly
  # when the force named argument is typically used
  # @param [boolean] force the action to happen even
  #    if the item is not ready or is disabled
  # @param [Admin::AppType] app_type to add the user access control to
  # @return [Admin::UserAccessControl] the created or updated user access control
  def add_user_access_controls(force: false, app_type: nil)
    return unless !persisted? || saved_change_to_disabled? || force

    begin
      if ready_to_generate? || disabled? || force
        app_type ||= admin.matching_user_app_type
        Admin::UserAccessControl.create_template_control admin,
                                                         app_type,
                                                         :table,
                                                         model_association_name,
                                                         disabled: disabled
      end
    rescue StandardError => e
      raise FphsException, "A failure occurred creating user access control for app with: #{model_association_name}." \
                           "\n#{e}"
    end
  end

  #
  # Get the field_list (or an alternative attribute string) as a
  # cleaned up array of strings
  # The string is a space or comma separated list
  # @param [String] for_attrib string from an alternative attribute
  # @return [Array] strings representing the list of fields
  def field_list_array(for_attrib: nil)
    for_attrib ||= field_list
    for_attrib.split(/[,\s]+/).map(&:strip).compact if for_attrib
  end

  #
  # Check if the implementation class has been correctly defined
  # This checks that the underlying database table has been created.
  # If the table is not available, (and we are in the development environment)
  # a migration for the appropriate schema will be written (and run)
  # @return [<Type>] <description>
  def check_implementation_class
    return unless !disabled && errors.empty?

    # Check the table exists. If not, generate a migration and create it if in development
    unless ready_to_generate? || !Rails.env.development?
      gs = generator_script(migration_version)
      migration_generator.write_db_migration(gs, table_name, migration_version)
      run_migration
    end

    # Check the implementation class is actually defined and can be instantiated
    begin
      res = implementation_class_defined?
    rescue StandardError => e
      err = "Failed to instantiate the class #{full_implementation_class_name}: #{e}"
      logger.warn err
      errors.add :name, err
      # Force exit of callbacks
      raise FphsException, err
    end

    # For some reason the underlying table exists but the class doesn't. Inform the admin
    unless res
      err = "The implementation of #{model_class_name} was not completed although " \
            "the DB table #{table_name} has been created."
      logger.warn err
      errors.add :name, err
      # Force exit of callbacks
      raise FphsException, err
    end
  end

  # If we have forced a regeneration of classes, for example if a new DB table
  # has been created, restart the server.
  # This is called from an after_commit trigger
  def restart_server
    AppControl.restart_server
  end

  def generate_migration
    return unless ready_to_generate?

    return unless migration_generator.migration_update_fields

    gs = generator_script(migration_version, 'update')
    fn = migration_generator.write_db_migration gs, table_name, migration_version, mode: 'update'
    @do_migration = fn
  end

  # Going forward we want the schema to be set explicitly.
  # For now, attempt to guess what it should be if it is not set
  # in the app type configuration
  def db_migration_schema
    current_user_app_type = current_admin.matching_user_app_type
    dsn = current_user_app_type&.default_schema_name
    return dsn if dsn

    res = category.split('-').first if category.present?
    res || Settings::DefaultMigrationSchema
  end

  def run_migration
    migration_generator.run_migration
  end

  def migration_version
    migration_generator.migration_version
  end

  def migration_generator
    @migration_generator ||=
      Admin::MigrationGenerator.new(
        db_migration_schema,
        table_name,
        all_implementation_fields(ignore_errors: false),
        table_comments,
        implementation_no_master_association
      )
  end
end
