# frozen_string_literal: true

module Dynamic
  module MigrationHandler
    extend ActiveSupport::Concern

    included do
      attr_accessor :table_comments # comments from definition to be applied to DB table

      after_create :generate_create_migration, if: -> { !disabled }

      after_save :generate_migration, if: -> { !disabled }
      after_save :run_migration, if: -> { @do_migration }
    end

    # Check the table exists. If not, generate a migration and create it if in development
    def generate_create_migration
      return if table_or_view_ready? || !Rails.env.development?

      gs = generator_script(migration_generator.migration_version)
      migration_generator.write_db_migration(gs, table_name, migration_generator.migration_version)
      run_migration
    end

    # Generate a migration triggered after_save.
    def generate_migration
      return if table_or_view_ready? || !Rails.env.development?

      # Return if there is nothing to update
      return unless migration_generator.migration_update_fields

      gs = generator_script(migration_generator.migration_version, 'update')
      fn = migration_generator.write_db_migration gs, table_name, migration_generator.migration_version, mode: 'update'
      @do_migration = fn
    end

    # Run a generated migration triggered after_save
    def run_migration
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
end
