class Admin::MigrationGenerator
  DefaultSchemaOwner = Settings::DefaultSchemaOwner
  DefaultMigrationSchema = Settings::DefaultMigrationSchema

  attr_accessor :db_migration_schema, :table_name, :all_implementation_fields,
                :table_comments, :no_master_association, :prev_table_name, :belongs_to_model,
                :allow_migrations, :db_configs, :resource_type, :view_sql

  #
  # Simply return the current connection
  def self.connection
    ActiveRecord::Base.connection
  end

  #
  # Get the app's schema search path and make it into a simple array
  # @return [Array]
  def self.current_search_paths
    connection.schema_search_path.split(',').map(&:strip)
  end

  #
  # Get the current database name for the connection
  # @return [String]
  def self.current_database
    connection.current_database
  end

  #
  # Get the current schema search_path, then quote each item and comma separate them for use in a query
  # @return [String]
  def self.quoted_schemas
    @quoted_schemas ||= current_search_paths.map { |s| "'#{s}'" }.join(',')
  end

  # Get the current list of table and views with the schema they belong to
  # This is limited to the current transaction visibility
  # @return [Array(Hash {schema_name, table_name})] array of schema_name and table_name hashes for each table
  def self.tables_and_views
    @tables_and_views ||=
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

  #
  # Does a table or view exist in the named schema, based on cached table and view names
  # @param [String] table_name - table or view name
  # @param [String] schema_name
  # @return [truthy | nil]
  def self.table_or_view_exists_in_schema?(table_name, schema_name)
    tables_and_views.find do |t|
      t['table_name'] == table_name && t['schema_name'] == schema_name
    end
  end

  # Reset the memoized tables and views value
  def self.tables_and_views_reset!
    @tables_and_views = nil
  end

  def self.table_comment(table_name, schema_name = nil)
    tn = []
    tn << schema_name if schema_name
    tn << table_name
    tn = tn.join('.')
    connection.table_comment(tn)
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

  #
  # Returns a list of foreign key definitions
  # @return [Array (Hash {constraint_name, source_schema, source_table, source_column, target_schema, target_table, target_column})]
  def self.foreign_keys
    Rails.cache.fetch("db_foreign_keys-#{Application.version}") do
      res = connection.execute <<~END_SQL

        SELECT
          o.conname AS constraint_name,
          (SELECT nspname FROM pg_namespace WHERE oid=m.relnamespace) AS source_schema,
          m.relname AS source_table,
          (SELECT a.attname FROM pg_attribute a WHERE a.attrelid = m.oid AND a.attnum = o.conkey[1] AND a.attisdropped = false) AS source_column,
          (SELECT nspname FROM pg_namespace WHERE oid=f.relnamespace) AS target_schema,
          f.relname AS target_table,
          (SELECT a.attname FROM pg_attribute a WHERE a.attrelid = f.oid AND a.attnum = o.confkey[1] AND a.attisdropped = false) AS target_column
        FROM
          pg_constraint o LEFT JOIN pg_class f ON f.oid = o.confrelid LEFT JOIN pg_class m ON m.oid = o.conrelid
        WHERE
          o.contype = 'f' AND o.conrelid IN (SELECT oid FROM pg_class c WHERE c.relkind = 'r');
      END_SQL

      res.to_a
    end
  end

  def self.data_dic(dd, nil_if_empty: false)
    ddtab = tables_and_views.find { |tn| tn['table_name'] == "#{dd}_datadic" }
    return unless ddtab

    ddtab = ddtab['table_name']

    Rails.cache.fetch("db_data_dic-#{dd}-#{Application.version}") do
      res = connection.execute <<~END_SQL
        SELECT * FROM #{ddtab};
      END_SQL
      res = res.to_a
      res = nil if nil_if_empty && res.blank?
      res
    end
  end

  #
  # Check the database for the table existing
  # This is potentially more current than #tables_and_views, which might be limited by the
  # current transaction or cached result
  # @param [String] table_name
  # @return [Boolean]
  def self.table_exists?(table_name)
    connection.table_exists?(table_name)
  end

  #
  # Check the database for the table or view existing
  # This is potentially more current than #tables_and_views, which might be limited by the
  # current transaction or cached result
  # @param [String] table_name
  # @return [Boolean]
  def self.table_or_view_exists?(table_name)
    connection.table_exists?(table_name) || connection.view_exists?(table_name)
  end

  #
  # Check the database for the view existing
  # This is potentially more current than #tables_and_views, which might be limited by the
  # current transaction or cached result
  # @param [String] table_name
  # @return [Boolean]
  def self.view_exists?(table_name)
    connection.view_exists?(table_name)
  end

  #
  # Generate the table name for the history table based on the current table name
  # @param [String] table_name
  # @return [String]
  def self.history_table_name_for(table_name)
    "#{table_name.singularize}_history"
  end

  #
  # Generate the field name used as a foreign key back onto the this table
  # based on the table name
  # @param [String] table_name
  # @return [String]
  def self.history_table_id_attr_for(table_name)
    "#{table_name.singularize}_id"
  end

  #
  # Get all the column names for a specified table
  # @param [String] table_name
  # @return [Array{String}]
  def self.table_column_names(table_name)
    connection.columns(table_name).map(&:name)
  end

  def initialize(db_migration_schema, table_name: nil, all_implementation_fields: nil, table_comments: nil,
                 no_master_association: nil, prev_table_name: nil, belongs_to_model: nil, db_configs: nil,
                 resource_type: nil,
                 view_sql: nil,
                 allow_migrations: nil)
    self.db_migration_schema = db_migration_schema
    self.table_name = table_name
    self.prev_table_name = prev_table_name
    self.resource_type = resource_type
    self.all_implementation_fields = all_implementation_fields
    self.table_comments = table_comments
    self.no_master_association = no_master_association
    self.belongs_to_model = belongs_to_model
    self.db_configs = db_configs
    self.view_sql = view_sql

    self.allow_migrations = allow_migrations
    self.allow_migrations = Settings::AllowDynamicMigrations if allow_migrations.nil?
    super()
  end

  def add_schema(export_type = nil)
    mig_text = schema_generator_script(db_migration_schema, 'create')
    write_db_migration mig_text, "#{db_migration_schema}_schema", export_type: export_type
  end

  # Standard columns are used by migrations
  def standard_columns
    pset = %w[id created_at updated_at contactid user_id master_id
              extra_log_type admin_id]
    pset += ["#{table_name.singularize}_table_id", "#{table_name.singularize}_id"]
    pset
  end

  def table_comment_changes
    begin
      comment = ActiveRecord::Base.connection.table_comment(table_name)
    rescue StandardError
      nil
    end
    new_comment = table_comments[:table]
    return unless comment != new_comment

    new_comment
  end

  def fields_comments_changes
    begin
      cols = if self.class.table_or_view_exists?(table_name)
               table_columns
             else
               migration_fields_array
             end
    rescue StandardError
      return
    end

    fields_comments = table_comments[:fields] || {}
    new_comments = {}

    fields_comments.each do |k, v|
      col = cols.select { |c| c.name == k.to_s }.first
      new_comments[k] = v if col && col.comment != v
    end

    new_comments
  end

  #
  # Get the SELECT definition of a view from Postgres,
  # or nil if the view doesn't exist
  # @param [String] schema
  # @param [String] view_name
  # @return [String | nil]
  def self.view_definition schema, view_name
    return unless view_exists?(view_name)

    sql = <<~SQL
      select definition
      from pg_views
      where viewname = $1 and schemaname = $2;
    SQL

    type  = ActiveModel::Type::String.new
    binds = [
      ActiveRecord::Relation::QueryAttribute.new('viewname', view_name, type),
      ActiveRecord::Relation::QueryAttribute.new('schemaname', schema, type)
    ]

    res = connection.exec_query sql, 'SQL', binds
    res.first && res.first['definition']
  end

  def table_columns
    ActiveRecord::Base.connection.columns(table_name)
  end

  def field_changes
    table_name = if table_name_changed
                   prev_table_name
                 else
                   self.table_name
                 end

    begin
      cols = table_columns
      old_colnames = cols.map(&:name) - standard_columns
      old_colnames = old_colnames.reject { |f| f.index(/^embedded_report_|^placeholder_/) }
    rescue StandardError
      return
    end

    fields = migration_fields_array
    new_colnames = fields.map(&:to_s) - standard_columns

    added = new_colnames - old_colnames
    removed = old_colnames - new_colnames
    changed = {}
    db_configs.each do |k, v|
      current_type = cols.find { |c| c.name == k.to_s }.type
      next unless v[:type] && current_type

      expected_type = v[:type]&.to_sym
      changed[k.to_s] = expected_type if current_type != expected_type
    end

    if belongs_to_model
      belongs_to_model_id = "#{belongs_to_model}_id"
      removed -= [belongs_to_model_id]
    end

    [added, removed, changed, old_colnames]
  end

  def table_name_changed
    prev_table_name && (prev_table_name != table_name)
  end

  def migration_update_table
    added, removed, changed, prev_fields = field_changes

    if table_comments
      new_table_comment = table_comment_changes
      new_fields_comments = fields_comments_changes
    end

    unless added.present? || removed.present? || changed.present? ||
           new_table_comment || new_fields_comments.present? || table_name_changed
      return
    end

    new_fields_comments ||= {}

    <<~ARCONTENT
      #{table_name_changed ? "    self.prev_table_name = '#{prev_table_name}'" : ''}
      #{table_name_changed ? '    update_table_name' : ''}
          self.prev_fields = %i[#{prev_fields.join(' ')}]
          \# added: #{added}
          \# removed: #{removed}
          \# changed type: #{changed}
      #{new_table_comment ? "    \# new table comment: #{new_table_comment.gsub("\n", '\n')}" : ''}
      #{new_fields_comments.present? ? "    \# new fields comments: #{new_fields_comments.keys}" : ''}
          update_fields
    ARCONTENT
  end

  def migration_update_view
    added, removed, changed, prev_fields = field_changes

    if table_comments
      new_table_comment = table_comment_changes
      new_fields_comments = fields_comments_changes
    end

    new_fields_comments ||= {}

    <<~ARCONTENT
      #{table_name_changed ? "    self.prev_table_name = '#{prev_table_name}'" : ''}
      #{table_name_changed ? '    update_table_name' : ''}
          self.prev_fields = %i[#{prev_fields.join(' ')}]
      #{new_table_comment ? "    \# new table comment: #{new_table_comment.gsub("\n", '\n')}" : ''}
      #{new_fields_comments.present? ? "    \# new fields comments: #{new_fields_comments.keys}" : ''}
          create_or_update_dynamic_model_view
    ARCONTENT
  end

  def migration_fields_array
    fields = all_implementation_fields
    fields.reject { |f| f.index(/^embedded_report_|^placeholder_/) }
  end

  def migration_set_attribs
    tcs = table_comments || {}
    view_sql_text = <<~VSTEXT
      self.view_sql = <<~VIEWSQL
        #{view_sql}
      VIEWSQL
    VSTEXT

    <<~SETATRRIBS
          self.schema = '#{db_migration_schema}'
          self.table_name = '#{table_name}'
          self.fields = %i[#{migration_fields_array.join(' ')}]
          self.table_comment = '#{tcs[:table]}'
          self.fields_comments = #{(tcs[:fields] || {}).to_json}
          self.db_configs = #{(db_configs || {}).to_json}
          self.no_master_association = #{!!no_master_association}
          self.resource_type = :#{resource_type}
      #{view_sql_text}
    SETATRRIBS
  end

  # Write a schema-specific migration only if we are in a development mode
  # @param [String] mig_text - the migration text to be written
  # @param [String | Symbol] name - underscored model name
  # @param [String] version - six character alphanumeric version
  # @param [String] mode - "create" or "update" type of migration
  # @param [String] export_type - optionally add a type "--export_type" suffix to the directory, "exports" for example
  # @return [String] full file path
  def write_db_migration(mig_text, name, version = nil, mode: 'create', export_type: nil)
    return unless allow_migrations

    version ||= migration_version

    dirname = db_migration_dirname export_type
    cname_us = "#{mode}_#{name}_#{version}"
    filepath = "#{dirname}/#{Time.new.to_s(:number)}_#{cname_us}.rb"
    FileUtils.mkdir_p dirname
    File.write(filepath, mig_text)
    # Cheat way to ensure multiple migrations can not have the same timestamp during app type loads
    sleep 1.2
    @do_migration = filepath
    filepath
  end

  # Does a previous table migration exist in the schema directory?
  # mode='*' for create or update
  # mode='create|update' for the appropriate type to check for
  def previous_table_migration_exists?(name, mode: '*', export_type: nil)
    dirname = db_migration_dirname export_type
    cname_us = "#{mode}_#{name}_??????"
    filepath = "#{dirname}/*_#{cname_us}.rb"
    Dir.glob(filepath).present?
  end

  def db_migration_dirname(export_type = nil)
    dirname = "db/app_migrations/#{db_migration_schema}"
    dirname += "--#{export_type}" if export_type
    dirname
  end

  def db_migration_failed_dirname
    'db/app_migrations/failed'
  end

  def run_migration
    return unless allow_migrations && db_migration_schema != DefaultMigrationSchema

    # Outside the current transaction
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::MigrationContext.new(db_migration_dirname).migrate
        # Don't dump until a build, otherwise differences in individual development environments
        # force unnecessary and confusing commits
        # pid = spawn('bin/rake db:structure:dump')
        # Process.detach pid
      end
    end.join

    self.class.tables_and_views_reset!

    true
  rescue StandardError => e
    FileUtils.mkdir_p db_migration_failed_dirname
    FileUtils.mv @do_migration, db_migration_failed_dirname
    raise FphsException, "Failed migration for path '#{db_migration_dirname}': #{e}"
  rescue FphsException => e
    FileUtils.mkdir_p db_migration_failed_dirname
    FileUtils.mv @do_migration, db_migration_failed_dirname
    raise FphsException, "Failed migration for path '#{db_migration_dirname}': #{e}"
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
