# frozen_string_literal: true

module Dynamic
  #
  # Generates migrations for dynamic models, activity logs and external identifiers when
  # a configuration is changed that requires a change to the database, then runs the migrations.
  # Migrations are stored a specific app directory 'app-migrations/<app name>'. If an attempt to
  # run a migration fails, the file will be moved to 'app-migrations/failed'.
  #
  # Additionally, on exporting an app type, a full set of migrations are exported to a
  # directory named 'app-migrations/<app name>--app-export/' so that a new environment can
  # be easily created.
  #
  # Migrations are only generated and run in a development environment, or on a server where
  # Settings::AllowDynamicMigrations is set.
  #
  # To run migrations that are not in the traditional Rails 'db/migrate' directory, for example
  # from an exported app, run:
  #
  #     MIG_PATH="<app name>--app-export" FPHS_LOAD_APP_TYPES=1 bundle exec rake db:migrate
  #
  # `db:rollback` also works.
  #
  # In addition to simple table creation and update, the migrations:
  # - handle bringing an existing table up to date, adding and removing any number of fields
  # - create associated history tables
  # - create an app schema when a new app is created (or uploaded)
  # - creates views between activity logs and the tables they reference
  module MigrationHandler
    extend ActiveSupport::Concern

    included do
      attr_accessor :table_comments # comments from definition to be applied to DB table
      attr_accessor :db_columns # field configurations from definition to be applied during creation
      alias_method :db_configs, :db_columns
      alias_method :db_configs=, :db_columns=
      attr_writer :allow_migrations

      before_validation :init_schema_name

      after_create :generate_create_migration, if: -> { !disabled }

      after_save :generate_migration, if: -> { !disabled }
      after_save :run_migration, if: -> { @do_migration }
    end

    #
    # Typically we only allow migrations in development, but an app setting
    # can allow this on servers running in Rails production that are used for
    # app development.
    def allow_migrations
      return @allow_migrations unless @allow_migrations.nil?

      @allow_migrations = Settings::AllowDynamicMigrations && !prevent_migrations
    end

    #
    # Check the table exists. If not, generate a migration and create it if in development
    def generate_create_migration
      return if @ran_migration || table_or_view_ready? || !allow_migrations

      raise FphsException, "Use a plural table name: #{table_name}" if table_name.singularize == table_name

      gs = migration_generator.generator_script(self.class)
      migration_generator.write_db_migration(gs, table_name, migration_generator.migration_version)
      run_migration
    end

    #
    # Check if the _configurations: view_sql: value has changed
    # in the last save
    def view_sql_changed?
      options_attr_name = self.class.option_configs_attr.to_s
      v1 = attribute_before_last_save(options_attr_name)
      v2 = attributes[options_attr_name]
      v1def = YAML.safe_load(v1, [], [], true)
      v2def = YAML.safe_load(v2, [], [], true)
      (v1def['_configurations'] && v1def['_configurations']['view_sql']) !=
        (v2def['_configurations'] && v2def['_configurations']['view_sql'])
    end

    #
    # Check if any of the reference views have not yet been defined
    def reference_views_missing?
      return unless respond_to? :all_reference_views

      (all_reference_views - Admin::MigrationGenerator.tables_and_views.map { |ts| ts['table_name'] }).present?
    end

    #
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
      return unless (!config_view_sql && migration_generator.migration_update_table) ||
                    (config_view_sql && view_sql_changed?) ||
                    (table_comments && (
                        migration_generator.table_comment_changes ||
                        migration_generator.fields_comments_changes.present?
                      )
                    ) ||
                    reference_views_missing? ||
                    saved_change_to_table_name? ||
                    (respond_to?(:saved_change_to_foreign_key_name?) && saved_change_to_foreign_key_name?)

      mode = 'update'
      gs = migration_generator.generator_script(self.class, mode)
      fn = migration_generator.write_db_migration gs, table_name, migration_generator.migration_version, mode: mode
      @do_migration = fn
    end

    #
    # Produce "create table" migration for this configuration
    def write_create_or_update_migration(export_type = nil, app_type_name = nil)
      return unless allow_migrations

      # Force re-parsing of the option configs, to ensure comments are correctly handled
      option_configs(force: true)
      mg = migration_generator(force_reset: true)
      mg.app_type_name = app_type_name
      mode = 'create_or_update'
      gs = mg.generator_script(self.class, mode)
      mg.write_db_migration(gs, table_name, mg.migration_version, mode: mode, export_type: export_type)
    end

    #
    # Run a generated migration triggered after_save
    def run_migration
      @ran_migration = true
      migration_generator.run_migration
    end

    #
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

    #
    # Dynamic model configurations define a view rather than table. This retrieves
    # the configuration SQL (the select statement) that specifies the view.
    #
    # The value
    #   _configurations:
    #     view_sql:
    # @return [String | nil]
    def config_view_sql
      return @config_view_sql if @config_view_sql

      option_configs
      @config_view_sql = configurations && configurations[:view_sql]
    end

    #
    # Set up and memoize a migration generator to be used for all DB and migration
    # related actions.
    # @return [Admin::MigrationGenerator]
    def migration_generator(force_reset: nil)
      return @migration_generator if @migration_generator && !force_reset

      btm = belongs_to_model if respond_to? :belongs_to_model

      # Ensure option_configs have been parsed
      option_configs

      art = all_referenced_tables if respond_to?(:all_referenced_tables)

      @migration_generator =
        Admin::MigrationGenerator.new(
          db_migration_schema,
          table_name: table_name,
          class_name: full_implementation_class_name,
          dynamic_def: self,
          all_implementation_fields: all_implementation_fields(ignore_errors: false),
          table_comments: table_comments,
          no_master_association: implementation_no_master_association,
          prev_table_name: table_name_before_last_save,
          belongs_to_model: btm,
          db_configs: db_columns,
          view_sql: config_view_sql,
          all_referenced_tables: art,
          resource_type: self.class.name.underscore.to_sym,
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
