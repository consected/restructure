# frozen_string_literal: true

module Dynamic
  module MigrationHandler
    extend ActiveSupport::Concern

    included do
      attr_accessor :table_comments # comments from definition to be applied to DB table
      attr_accessor :db_configs # field configurations from definition to be applied during creation
      attr_writer :allow_migrations

      before_validation :init_schema_name

      after_create :generate_create_migration, if: -> { !disabled }

      after_save :generate_migration, if: -> { !disabled }
      after_save :run_migration, if: -> { @do_migration }
    end

    def allow_migrations
      return @allow_migrations unless @allow_migrations.nil?

      @allow_migrations = Settings::AllowDynamicMigrations
    end

    # Check the table exists. If not, generate a migration and create it if in development
    def generate_create_migration
      return if @ran_migration || table_or_view_ready? || !allow_migrations

      raise FphsException, "Use a plural table name: #{table_name}" if table_name.singularize == table_name

      gs = generator_script(migration_generator.migration_version)
      migration_generator.write_db_migration(gs, table_name, migration_generator.migration_version)
      run_migration
    end

    # Generate a migration triggered after_save.
    def generate_migration
      # Re-enabling an item requires it to be created
      if saved_change_to_disabled?
        generate_create_migration
        return
      end

      @do_migration = nil
      return if @ran_migration || !allow_migrations

      # Force re-parsing of the option configs, to ensure comments are correctly handled
      option_configs(force: true)

      # Return if there is nothing to update
      return unless migration_generator.migration_update_table || saved_change_to_table_name?

      mode = 'update'
      gs = generator_script(migration_generator.migration_version, mode)
      fn = migration_generator.write_db_migration gs, table_name, migration_generator.migration_version, mode: mode
      @do_migration = fn
    end

    #
    # Produce "create table" migration for this configuration
    def write_create_or_update_migration(export_type = nil)
      return unless allow_migrations

      # Force re-parsing of the option configs, to ensure comments are correctly handled
      option_configs(force: true)
      mg = migration_generator(force_reset: true)
      mode = 'create_or_update'
      gs = generator_script(mg.migration_version, mode)

      mg.write_db_migration(gs, table_name, mg.migration_version, mode: mode, export_type: export_type)
    end

    # Run a generated migration triggered after_save
    def run_migration
      @ran_migration = true
      migration_generator.run_migration
    end

    # Going forward we want the schema to be set explicitly.
    # For now, attempt to guess what it should be if it is not set
    # in the app type configuration
    def db_migration_schema
      return schema_name if respond_to?(:schema_name) && schema_name.present?

      current_user_app_type = current_admin.matching_user_app_type
      dsn = current_user_app_type&.default_schema_name
      return dsn if dsn

      res = category.split('-').first if category.present?
      res ||= Settings::DefaultMigrationSchema
      return res if res.present?

      # Default to the first in the search path if nothing else works
      Admin::MigrationGenerator.current_search_paths.first
    end

    # Set up and memoize a migration generator to be used for all DB and migration
    # related actions
    def migration_generator(force_reset: nil)
      return @migration_generator if @migration_generator && !force_reset

      btm = belongs_to_model if respond_to? :belongs_to_model

      # Ensure option_configs have been parsed
      option_configs

      @migration_generator =
        Admin::MigrationGenerator.new(
          db_migration_schema,
          table_name,
          all_implementation_fields(ignore_errors: false),
          table_comments,
          implementation_no_master_association,
          table_name_before_last_save,
          btm,
          db_configs,
          self.class.name.underscore.to_sym,
          allow_migrations: allow_migrations
        )
    end

    #
    # If a schema_name has not been set, initialize it with the default for the current application
    # or the default for server
    # @return [String] new schema_name
    def init_schema_name
      return if disabled?

      self.schema_name = db_migration_schema
    end
  end
end
