class Admin::MigrationGenerator
  DefaultSchemaOwner = Settings::DefaultSchemaOwner
  DefaultMigrationSchema = Settings::DefaultMigrationSchema

  attr_accessor :db_migration_schema

  def self.connection
    ActiveRecord::Base.connection
  end

  def self.quoted_schemas
    @quoted_schemas ||= current_search_paths.map { |s| "'#{s}'" }.join(',')
  end

  # Get the current list of table and views with the schema they belong to
  #
  # @return [Array(Hash {schema_name, table_name})] array of schema_name and table_name hashes for each table
  def self.tables_and_views
    connection.execute <<~END_SQL
      select table_schema "schema_name", table_name from information_schema.tables 
      where table_schema IN (#{quoted_schemas})
      and table_catalog = '#{current_database}'
      UNION 
      select table_schema "schema_name", table_name from information_schema.views
      where table_schema IN (#{quoted_schemas})
      and table_catalog = '#{current_database}'
      order by "schema_name", table_name
    END_SQL
  end

  def self.table_comment(table_name)
    connection.table_comment(table_name)
  end

  def self.current_search_paths
    connection.schema_search_path.split(',')
  end

  def self.current_database
    connection.current_database
  end

  def self.column_comments
    Rails.cache.fetch("db_column_comments-#{Application.version}") do
      res = connection.execute <<~END_SQL
        SELECT
            cols.table_schema "schema_name",
            cols.table_name,
            cols.column_name,
            pg_catalog.col_description(c.oid, cols.ordinal_position::int) AS column_comment
        FROM
            information_schema.columns cols
        INNER JOIN pg_catalog.pg_class c
        ON 
          c.oid = ('"' || cols.table_name || '"')::regclass::oid
          AND c.relname = cols.table_name

        WHERE
            cols.table_catalog = '#{current_database}' AND
            cols.table_schema IN (#{quoted_schemas}) AND
            pg_catalog.col_description(c.oid, cols.ordinal_position::int) IS NOT NULL
        ;
      END_SQL

      res.to_a
    end
  end

  def initialize(db_migration_schema)
    self.db_migration_schema = db_migration_schema
    super()
  end

  def add_schema
    mig_text = schema_generator_script(db_migration_schema, 'create')
    write_db_migration mig_text, "#{db_migration_schema}_schema"
  end

  # Write a schema-specific migration only if we are in a development mode
  def write_db_migration(mig_text, name, version = nil, mode: 'create')
    return unless Rails.env.development?

    version ||= migration_version

    dirname = db_migration_dirname
    cname_us = "#{mode}_#{name}_#{version}"
    fn = "#{dirname}/#{Time.new.to_s(:number)}_#{cname_us}.rb"
    FileUtils.mkdir_p dirname
    File.write(fn, mig_text)
    # Cheat way to ensure multiple migrations can not have the same timestamp during app type loads
    sleep 1.2
    @do_migration = fn
    fn
  end

  def db_migration_dirname
    "db/app_migrations/#{db_migration_schema}"
  end

  def db_migration_failed_dirname
    'db/app_migrations/failed'
  end

  def run_migration
    return unless Rails.env.development? && db_migration_schema != DefaultMigrationSchema

    # Outside the current transaction
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::MigrationContext.new(db_migration_dirname).migrate
        pid = spawn('bin/rake db:schema:dump')
        Process.detach pid
      end
    end.join

    true
  rescue StandardError => e
    FileUtils.mkdir_p db_migration_failed_dirname
    FileUtils.mv @do_migration, db_migration_failed_dirname
    raise e
  rescue FphsException => e
    FileUtils.mkdir_p db_migration_failed_dirname
    FileUtils.mv @do_migration, db_migration_failed_dirname
    raise e
  end

  def migration_version
    @migration_version ||= DateTime.now.to_i.to_s(36)
  end

  private

  def schema_generator_script(schema_name, mode = 'create', owner: DefaultSchemaOwner)
    cname = "#{mode}_#{schema_name}_schema_#{migration_version}".camelize

    <<~CONTENT
      require 'active_record/migration/app_generator'
      class #{cname} < ActiveRecord::Migration[5.2]
        include ActiveRecord::Migration::AppGenerator

        def change
          self.schema = '#{schema_name}'
          self.owner = '#{owner}'
          create_schema
        end
      end
    CONTENT
  end
end
