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
      validate :schema_name_ok
      validate :table_name_ok
      after_create :generate_create_migration, if: -> { !disabled }

      after_save :generate_migration, if: -> { !disabled }
      after_save :run_migration, if: -> { @do_migration }
    end

    class_methods do
      def default_schema_name(app_type: nil, category: nil)
        dsn = app_type&.default_schema_name
        return dsn if dsn.present?

        res = category.split('-').first if category.present?
        res = nil unless Admin::MigrationGenerator.current_search_paths.include?(res)
        res ||= Settings::DefaultMigrationSchema
        return res if res.present?

        # Default to the first in the search path if nothing else works
        Admin::MigrationGenerator.current_search_paths.first
      end

      def default_category(app_type: nil)
        app_type&.name&.id_underscore
      end
    end

    #
    # App settings can allow migrations on servers running in Rails production that are used for
    # app development.
    # In the test environment, we don't memoize the value, since the server settings may change
    # between tests that reuse a dynamic definition.
    def allow_migrations
      unless @allow_migrations.nil? || Rails.env.test?
        Rails.logger.warn "Migrations not allowed for #{schema_name}" unless @allow_migrations
        return @allow_migrations
      end

      @allow_migrations = Settings::AllowDynamicMigrations && !prevent_migrations
      Rails.logger.warn "Migrations not allowed for #{schema_name}" unless @allow_migrations
      @allow_migrations
    end

    def app_import_prevents_migrations?
      Admin::AppTypeImport.prevent_migrations?
    end

    #
    # Check the table exists. If not, generate a migration and create it if in development
    def generate_create_migration
      return if @ran_migration || table_or_view_ready? || !allow_migrations || app_import_prevents_migrations?

      raise FphsException, "Use a plural table name: #{table_name}" if table_name.singularize == table_name

      gs = migration_generator.generator_script(self.class)
      migration_generator.write_db_migration(gs, table_name)
      run_migration
    end

    #
    # Check if the _configurations: view_sql: value has changed
    # in the last save
    def view_sql_changed?
      return unless config_view_sql
      return true if saved_change_to_disabled? && !disabled

      v1_sql, v2_sql = saved_configurations_key_change('view_sql')
      changed = (v1_sql != v2_sql)
      if changed
        Rails.logger.info "In migration, the view_sql for #{table_name} is going to change (from/to):\n" \
                          "\n-------#{v1_sql}\n-------\n#{v2_sql}\n-------"
      end
      !!changed
    end

    #
    # Check if the _configurations: view_skip_updates: value has changed in the last save
    def view_skip_updates_changed?
      return unless config_view_sql
      return true if saved_change_to_disabled? && !disabled

      v1_val, v2_val = saved_configurations_key_change('view_skip_updates')
      !!(v1_val != v2_val)
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
      if saved_change_to_disabled? || !table_or_view_ready?
        generate_create_migration
        return
      end

      @do_migration = nil
      return if @ran_migration || !allow_migrations

      # Force re-parsing of the option configs, to ensure comments are correctly handled
      result = option_configs(force: true, return_value_on_error: nil)
      return unless result

      # Return if there is nothing to update
      return unless (!config_view_sql && migration_generator.migration_update_table) ||
                    (config_view_sql && (view_sql_changed? || view_skip_updates_changed?)) ||
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
      fn = migration_generator.write_db_migration(gs, table_name, mode:)
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
      mg.write_db_migration(gs, table_name, mode:, export_type:)
    end

    #
    # Run a generated migration triggered after_save
    def run_migration
      return if @ran_migration || !allow_migrations

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

      unless current_user_app_type
        Rails.logger.warn "#{self.class.human_name} migration doesn't specify a schema_name and there is no matching user " \
                          "for the current admin '#{current_admin.email}' or no app type is set '#{current_user_app_type}'"
      end

      Rails.logger.warn "#{self.class.human_name} doesn't specify a schema_name - using the app type default, category or first in search path"
      self.class.default_schema_name(app_type: current_user_app_type, category:)
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
    # Whether the view should be given a dummy INSTEAD OF trigger so it appears updatable.
    #
    # The value
    #   _configurations:
    #     view_skip_updates:
    # @return [Boolean]
    def config_view_skip_updates?
      option_configs
      !!(configurations && configurations[:view_skip_updates])
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
          table_name:,
          class_name: full_implementation_class_name,
          dynamic_def: self,
          all_implementation_fields: all_implementation_fields(ignore_errors: false),
          table_comments:,
          no_master_association: implementation_no_master_association,
          no_user_id: implementation_no_user_id,
          prev_table_name: table_name_before_last_save,
          belongs_to_model: btm,
          db_configs: db_columns,
          view_sql: config_view_sql,
          view_sql_changed: view_sql_changed?,
          view_skip_updates: config_view_skip_updates?,
          all_referenced_tables: art,
          resource_type: self.class.name.underscore.to_sym,
          allow_migrations:
        )
    end

    #
    # If a schema_name has not been set, initialize it with the default for the current application
    # or the default for server
    # @return [String] new schema_name
    def init_schema_name
      return if disabled? || schema_name.present?

      self.schema_name = if persisted?
                           schema_name_in_db
                         else
                           db_migration_schema
                         end
    end

    def table_name_ok
      return true if disabled? || table_name.blank? || table_name.id_underscore == table_name

      errors.add :table_name, "must only include characters acceptable to the database: #{table_name}"
    end

    #
    # Parse the previous and current saved options YAML, returning the before/after
    # value of a single _configurations key, for change detection (e.g. view_sql,
    # view_skip_updates). Broken YAML is treated as nil rather than raising.
    # @param [String] config_key - the _configurations key to compare
    # @return [Array(Object, Object)] before, after values
    def saved_configurations_key_change(config_key)
      options_attr_name = self.class.option_configs_attr.to_s
      v1 = attribute_before_last_save(options_attr_name) || ''
      v2 = attributes[options_attr_name] || ''
      v1 = v1.sub("---\n", '')
      v2 = v2.sub("---\n", '')
      v1 = OptionConfigs::ExtraOptions.prepend_standard_definitions(v1)
      v2 = OptionConfigs::ExtraOptions.prepend_standard_definitions(v2)
      v1 = OptionConfigs::ExtraOptions.include_libraries(v1)
      v2 = OptionConfigs::ExtraOptions.include_libraries(v2)
      [parse_configurations_value(v1, config_key, 'previous'), parse_configurations_value(v2, config_key, 'current')]
    end

    #
    # @return [Object, nil]
    def parse_configurations_value(yaml_text, config_key, which)
      return unless yaml_text

      def_hash = YAML.safe_load(yaml_text, permitted_classes: [], permitted_symbols: [], aliases: true)
      def_hash.dig('_configurations', config_key)
    rescue Psych::Exception => e
      Rails.logger.warn "Error parsing #{which} YAML for #{config_key} in #{table_name}: #{e.message}"
      nil
    end

    def schema_name_ok
      return true if disabled? || Admin::MigrationGenerator.current_search_paths.include?(schema_name)

      errors.add :schema_name, "(#{schema_name}) not in current search_path for #{table_name} - " \
                               "#{Admin::MigrationGenerator.current_search_paths}\#{nattributes}"
    end
  end
end
