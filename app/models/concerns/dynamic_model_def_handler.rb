# frozen_string_literal: true

module DynamicModelDefHandler
  extend ActiveSupport::Concern

  DefaultMigrationSchema = Settings::DefaultMigrationSchema

  included do
    after_save :generate_model
    after_save :check_implementation_class
    # Reload the routes based on specific controller actions, to allow app type uploads to work faster
    # after_save :reload_routes
    after_save :add_master_association, if: -> { @regenerate }
    after_save :add_user_access_controls, if: -> { @regenerate }
    after_save :generate_migration

    after_commit :update_tracker_events, if: -> { @regenerate }
    after_commit :restart_server, if: -> { @regenerate }
    after_commit :other_regenerate_actions
  end

  class_methods do
    def implementation_prefix
      nil
    end

    # This is intentionally a class variable, to capture the model names for all dynamic models
    def model_names
      @model_names ||= []
    end

    def model_names=(m)
      @model_names = m
    end

    def model_name_strings
      model_names.map(&:to_s)
    end

    def models
      @models ||= {}
    end

    def preload
      nil
    end

    def active_model_configurations
      olat = Admin::AppType.active_app_types

      if olat && !olat.empty?
        dma = []
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

    def define_models
      preload

      begin
        dma = active_model_configurations

        logger.info "Generating models #{name} #{active.length}"

        dma.each do |dm|
          res = dm.generate_model
          # Force the admin for cases that this is run outside of the admin console
          # It is expected that this is mostly when originally seeding the database
          dm.current_admin ||= dm.admin

          dm.update_tracker_events
        end
      rescue Exception => e
        Rails.logger.warn "Failed to generate models. Hopefully this is only during a migration. #{e.inspect}"
        puts "Failed to generate models. Hopefully this is only during a migration. #{e.inspect}"
      end
    end

    def routes_reload
      return unless @regenerate

      Rails.application.reload_routes!
      Rails.application.routes_reloader.reload!
    end

    def enable_active_configurations
      # to ensure that the db migrations can run, check for the existence of the admin table
      # before attempting to use it. Otherwise Rake tasks fail.
      if ActiveRecord::Base.connection.table_exists? table_name
        active_model_configurations.each do |dm|
          klass = if dm.is_a? ExternalIdentifier
                    Object
                  else
                    dm.class.name.constantize
                  end

          if !dm.disabled && dm.ready? && dm.implementation_class_defined?(klass, fail_without_exception: true)
            dm.add_master_association
          else
            puts "Failed to enable #{dm} #{dm.id}"
            Rails.logger.warn "Failed to enable #{dm} #{dm.id}"
          end
        end
      else
        puts "Table doesn't exist yet: #{table_name}"
      end
    end
  end

  def is_active_model_configuration?
    self.class.active_model_configurations.include? self
  end

  def implementation_controller_defined?(parent_class = Module)
    return false unless full_implementation_controller_name

    # Check that the class is defined
    klass = parent_class.const_get(full_implementation_controller_name)
    res = klass.is_a?(Class)
    res
  rescue NameError
    false
  end

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
      if opt[:fail_without_exception]
        # By default, return false if an error occurred attempting the initialization.
        # In certain cases (for example, checking if a class exists so it can be removed), returning true if the
        # class is defined regardless of whether it can be initialized makes most sense. Provide an option to support this.
        opt[:fail_without_exception_newable_result]
      else
        raise FphsException, err
      end
    end
  rescue NameError
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

  def ready?
    cn = ActiveRecord::Base.connection
    cn.table_exists?(table_name) || cn.view_exists?(table_name)
  rescue StandardError => e
    puts e
    @extra_error = e

    false
  end

  # This needs to be overridden in each provider to allow consistency of calculating model names for implementations
  def implementation_model_name
    nil
  end

  def model_class_name
    implementation_model_name.ns_camelize
  end

  def model_def_name
    implementation_model_name.to_sym
  end

  def model_def
    self.class.models[model_def_name]
  end

  def model_data_template_name
    model_association_name.to_s.hyphenate
  end

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

  def full_implementation_class_name
    full_item_type_name.ns_camelize
  end

  def full_implementation_controller_name
    "#{model_class_name.pluralize}Controller"
  end

  def implementation_class
    full_implementation_class_name.ns_constantize
  end

  def update_tracker_events
    raise 'DynamicModel configuration implementation must define update_tracker_events'
  end

  def other_regenerate_actions; end

  def add_model_to_list(m)
    tn = model_def_name
    self.class.models[tn] = m
    logger.info "Added new model #{tn}"
    self.class.model_names << tn unless self.class.model_names.include? tn
  end

  def remove_model_from_list
    tn = model_def_name
    logger.info "Removed disabled model #{tn}"
    self.class.models.delete(tn)
    self.class.model_names -= [tn]
  end

  def remove_assoc_class(in_class_name)
    # Dump the old association

    assoc_ext_name = "#{in_class_name}#{model_class_name.pluralize}AssociationExtension"
    Object.send(:remove_const, assoc_ext_name) if implementation_class_defined?(Object)
  rescue StandardError => e
    logger.debug "Failed to remove #{assoc_ext_name} : #{e}"
    # puts "Failed to remove #{assoc_ext_name} : #{e}"
  end

  def reload_routes
    self.class.routes_reload
  end

  def add_user_access_controls(force: false, app_type: nil)
    if !persisted? || saved_change_to_disabled? || force
      begin
        if ready? || disabled? || force
          app_type ||= admin.matching_user_app_type
          # Admin::UserAccessControl.create_control_for_all_apps admin, :table, model_association_name, disabled: disabled
          Admin::UserAccessControl.create_template_control admin, app_type, :table, model_association_name, disabled: disabled
        end
      rescue StandardError => e
        raise FphsException, "A failure occurred creating user access control for all apps with: #{model_association_name}.\n#{e}"
      end
    end
  end

  def field_list_array(for_attrib: nil)
    for_attrib ||= field_list
    for_attrib.split(/[,\s]+/).map(&:strip).compact if for_attrib
  end

  def check_implementation_class
    if !disabled && errors.empty?

      unless !disabled? && ready?

        gs = generator_script
        fn = write_db_migration gs

        err = "The implementation of #{model_class_name} was not completed. Ensure the DB table #{table_name} has been created.

        Wrote migration to: #{fn}
        Review it, then run migration with:
        MIG_PATH=femfl FPHS_LOAD_APP_TYPES= bundle exec rails db:migrate

        IMPORTANT: to save this configuration, check the Disabled checkbox and re-submit.
        "

        err += "(extra error info: #{@extra_error})" if @extra_error

        raise FphsException, err
      end

      begin
        res = implementation_class_defined?
      rescue StandardError => e
        err = "Failed to instantiate the class #{full_implementation_class_name}: #{e}"
        logger.warn err
        errors.add :name, err
        # Force exit of callbacks
        raise FphsException, err
      end
      unless res
        err = "The implementation of #{model_class_name} was not completed although the DB table #{table_name} has been created."
        logger.warn err
        errors.add :name, err
        # Force exit of callbacks
        raise FphsException, err
      end
    end
  end

  def restart_server
    AppControl.restart_server
  end

  # Standard columns are used by migrations
  def standard_columns
    pset = %w[id created_at updated_at contactid user_id master_id
              extra_log_type admin_id]
    pset += ["#{table_name.singularize}_table_id", "#{table_name.singularize}_id"]
    pset
  end

  def generate_migration
    return unless ready?

    begin
      cols = ActiveRecord::Base.connection.columns(table_name)
      old_colnames = cols.map(&:name) - standard_columns
    rescue StandardError
      return
    end

    fields = all_implementation_fields(ignore_errors: true)
    new_colnames = fields.map(&:to_s) - standard_columns

    added = new_colnames - old_colnames
    removed = old_colnames - new_colnames

    if added.present? || removed.present?
      gs = generator_script('update', added, removed)
      write_db_migration gs, mode: 'update'
    end
  end

  # A DB migration schema is either the schema of the currrent app,
  # or is based on the category of the dynamic model, activity log or external ID
  def db_migration_schema
    current_user_app_type = current_admin.matching_user_app_type
    dsn = current_user_app_type&.default_schema_name
    return dsn if dsn

    res = category.split('-').first if category.present?
    res || DefaultMigrationSchema
  end

  def db_migration_dirname
    "db/app_migrations/#{db_migration_schema}"
  end

  def write_db_migration(mig_text, mode: 'create')
    return if Rails.env.test?

    dirname = "db/app_migrations/#{db_migration_schema}"
    fn = "#{dirname}/#{Time.new.to_s(:number)}_#{mode}_#{table_name}.rb"
    FileUtils.mkdir_p dirname
    File.write(fn, mig_text)
    fn
  end
end
