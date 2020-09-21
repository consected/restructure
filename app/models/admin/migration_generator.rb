class Admin::MigrationGenerator
  DefaultSchemaOwner = Settings::DefaultSchemaOwner
  DefaultMigrationSchema = Settings::DefaultMigrationSchema

  attr_accessor :db_migration_schema

  # Get the current list of table and views with the schema they belong to
  #
  # @return [Array(Hash {table_schema, table_name})] array of table_schema and table_name hashes for each table
  def self.tables_and_views
    cn = ActiveRecord::Base.connection

    schemas = current_search_paths.map { |s| "'#{s}'" }.join(',')

    cn.execute <<~END_SQL
      select table_schema, table_name from information_schema.tables 
      where table_schema IN (#{schemas})
      UNION 
      select table_schema, table_name from information_schema.views
      where table_schema IN (#{schemas})
      order by table_schema, table_name
    END_SQL
  end

  def self.current_search_paths
    cn = ActiveRecord::Base.connection
    cn.schema_search_path.split(',')
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
    FileUtils.rm @do_migration
    raise e
  rescue FphsException => e
    FileUtils.rm @do_migration
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
