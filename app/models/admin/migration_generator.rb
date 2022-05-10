# frozen_string_literal: true

require 'timeout'
#
# Provides database level functionality to support dynamic migration generation
# and functions that are used to access features of the database across the application.
class Admin::MigrationGenerator
  DefaultSchemaOwner = Settings::DefaultSchemaOwner
  DefaultMigrationSchema = Settings::DefaultMigrationSchema

  attr_accessor :db_migration_schema, :table_name, :all_implementation_fields,
                :table_comments, :no_master_association, :prev_table_name, :belongs_to_model,
                :allow_migrations, :db_configs, :resource_type, :view_sql, :all_referenced_tables,
                :class_name, :dynamic_def, :app_type_name

  def initialize(db_migration_schema, table_name: nil, class_name: nil,
                 all_implementation_fields: nil, table_comments: nil,
                 no_master_association: nil, prev_table_name: nil, belongs_to_model: nil, db_configs: nil,
                 resource_type: nil,
                 view_sql: nil,
                 allow_migrations: nil,
                 all_referenced_tables: nil,
                 dynamic_def: nil)
    self.db_migration_schema = db_migration_schema
    self.table_name = table_name
    self.class_name = class_name
    self.prev_table_name = prev_table_name
    self.resource_type = resource_type
    self.all_implementation_fields = all_implementation_fields
    self.table_comments = table_comments
    self.no_master_association = no_master_association
    self.belongs_to_model = belongs_to_model
    self.db_configs = db_configs
    self.view_sql = view_sql
    self.all_referenced_tables = all_referenced_tables
    self.dynamic_def = dynamic_def

    self.allow_migrations = allow_migrations
    self.allow_migrations = Settings::AllowDynamicMigrations if allow_migrations.nil?
    super()
  end

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

  #
  # Reset the memoized tables and views value
  def self.tables_and_views_reset!
    @tables_and_views = nil
  end

  #
  # Get the database comment for the table
  # @param [String] table_name
  # @param [String] schema_name - optional schema name
  # @return [String]
  def self.table_comment(table_name, schema_name = nil)
    tn = []
    tn << schema_name if schema_name
    tn << table_name
    tn = tn.join('.')
    connection.table_comment(tn)
  end

  #
  # Get and cache database comments for all columns for all tables
  # in the search path.
  # Each entry is a Hash: { schema_name: , table_name: , column_name: , column_comment: }
  # @return [Array{Hash}]
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
  # Returns a list of foreign key definitions for all tables in the search path.
  # Returns an array of hashes that link source and target:
  # { constraint_name: , source_schema: , source_table: , source_column: ,
  #   target_schema: , target_table: , target_column: }
  # @return [Array {Hash}]
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

  #
  # Generate a data dictionary table name related to the provided table name
  # and check if it exists.
  # If it does, run a query to retrieve the full data dictionary content as an array,
  # caching it for future use,
  # @param [String] basename
  # @param [true|false] nil_if_empty - return a nil result rather than empty array
  # @return [Array{Hash}] - return results
  def self.data_dic(basename, nil_if_empty: false)
    ddtab = tables_and_views.find { |tn| tn['table_name'] == "#{basename}_datadic" }
    return unless ddtab

    ddtab = ddtab['table_name']

    Rails.cache.fetch("db_data_dic-#{basename}-#{Application.version}") do
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

  #
  # Create a migration to add a schema
  # @param [String] export_type - a suffix to add to the migration name,
  #                               such as 'app-export'
  def add_schema(export_type = nil)
    mig_text = schema_generator_script(db_migration_schema, 'create')
    write_db_migration mig_text, "#{db_migration_schema}_schema", export_type: export_type
  end

  #
  # Standard columns are used when running migrations, to avoid user specified columns
  # duplicating standard app columns for current table_name
  # @return [Array]
  def standard_columns
    pset = %w[id created_at updated_at contactid user_id master_id
              extra_log_type admin_id]
    pset += ["#{table_name.singularize}_table_id", "#{table_name.singularize}_id"]
    pset
  end

  #
  # Get the table or view comment for the current table_name
  # @return [String | nil]
  def table_or_view_comment
    if self.class.view_exists?(table_name)
      res = self.class.connection.execute "select obj_description('#{table_name}'::regclass) c"
      res[0]['c']
    else
      ActiveRecord::Base.connection.table_comment(table_name)
    end
  rescue StandardError
    nil
  end

  #
  # Identify change to database table or view comment based on the
  # current table_comments configuration
  # @return [String|nil] - new comment, or nil if unchanged
  def table_comment_changes
    comment = table_or_view_comment
    new_comment = table_comments[:table]
    return unless comment != new_comment

    new_comment
  end

  #
  # Identify changes to database table column comments
  # based on the current table_comments configuration
  # @return [Array{Hash}] - array of only changed comments { col_name: new_comment }
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
  def self.view_definition(schema, view_name)
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

  #
  # Get the SELECT definition of multiple view matching a LIKE from Postgres
  # @param [String] schema
  # @param [String] view_name
  # @return [Array]
  def self.view_definitions(schema, view_name)
    sql = <<~SQL
      select schemaname, viewname, definition
      from pg_views
      where viewname LIKE $1 and schemaname = $2;
    SQL

    type  = ActiveModel::Type::String.new
    binds = [
      ActiveRecord::Relation::QueryAttribute.new('viewname', view_name, type),
      ActiveRecord::Relation::QueryAttribute.new('schemaname', schema, type)
    ]

    connection.exec_query sql, 'SQL', binds
  end

  def table_columns
    ActiveRecord::Base.connection.columns(table_name)
  end

  #
  # Find field changes, returning an array of arrays:
  # [ [added], [removed], [changed], [old_colnames] ]
  # @return [Array]
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
      current_type = cols.find { |c| c.name == k.to_s }&.type
      next unless v[:type] && current_type

      expected_type = v[:type]&.to_sym
      current_type = :timestamp if current_type == :datetime
      changed[k.to_s] = expected_type if current_type != expected_type
    end

    if belongs_to_model
      belongs_to_model_id = "#{belongs_to_model}_id"
      removed -= [belongs_to_model_id]
    end

    [added, removed, changed, old_colnames]
  end

  #
  # Has the configured table name changed?
  # @return [true|false]
  def table_name_changed
    prev_table_name && (prev_table_name != table_name)
  end

  #
  # Content for a migration file for a table update
  # @return [String]
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
      #{table_name_changed ? '' : "    self.prev_fields = %i[#{prev_fields.join(' ')}]"}
          \# added: #{added}
          \# removed: #{removed}
          \# changed type: #{changed}
      #{new_table_comment ? "    \# new table comment: #{new_table_comment.gsub("\n", '\n')}" : ''}
      #{new_fields_comments.present? ? "    \# new fields comments: #{new_fields_comments.keys}" : ''}
          update_fields
    ARCONTENT
  end

  #
  # Content for a migration file for a view update
  # @return [String]
  def migration_update_view
    _added, _removed, _changed, prev_fields = field_changes

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

  #
  # All user defined fields expected by the dynamic definition
  # @return [Array{String}]
  def migration_fields_array
    fields = all_implementation_fields
    fields.reject { |f| f.index(/^embedded_report_|^placeholder_/) }
  end

  #
  # Content representing the setting of key attributes for the migration
  # @return [String]
  def migration_set_attribs
    tcs = table_comments || {}

    if view_sql&.strip&.present?
      view_sql_text = <<~VSTEXT
        self.view_sql = <<~VIEWSQL
          #{view_sql}
        VIEWSQL
      VSTEXT
    end

    <<~SETATTRIBS
          self.schema = '#{db_migration_schema}'
          self.table_name = '#{table_name}'
          self.class_name = '#{class_name}'
          self.fields = %i[#{migration_fields_array.join(' ')}]
          self.table_comment = '#{tcs[:table]}'
          self.fields_comments = #{(tcs[:fields] || {}).to_h}
          self.db_configs = #{(db_configs || {}).to_h}
          self.no_master_association = #{!!no_master_association}
          self.resource_type = :#{resource_type}
          self.all_referenced_tables = #{(all_referenced_tables || []).to_a}
      #{view_sql_text}
    SETATTRIBS
  end

  #
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

    # Ensure we don't get overlapping migration version numbers
    migtime = Time.new.to_s(:number)
    while Dir.glob("#{migtime}*", base: dirname).length > 0
      sleep 1.5
      migtime = Time.new.to_s(:number)
    end

    filepath = "#{dirname}/#{migtime}_#{cname_us}.rb"

    FileUtils.mkdir_p dirname
    File.write(filepath, mig_text)
    # Cheat way to ensure multiple migrations can not have the same timestamp during app type loads
    sleep 1.2
    @do_migration = filepath
    filepath
  end

  #
  # Does a previous table migration exist in the schema directory?
  # mode='*' for create or update
  # mode='create|update' for the appropriate type to check for
  def previous_table_migration_exists?(name, mode: '*', export_type: nil)
    dirname = db_migration_dirname export_type
    cname_us = "#{mode}_#{name}_??????"
    filepath = "#{dirname}/*_#{cname_us}.rb"
    Dir.glob(filepath).present?
  end

  #
  # Relative path to the migrations directory
  # @param [String] export_type - suffix, for example 'app-export'
  # @return [String]
  def db_migration_dirname(export_type = nil)
    loc = app_type_name || db_migration_schema
    dirname = "db/app_migrations/#{loc}"
    dirname += "--#{export_type}" if export_type
    dirname
  end

  #
  # Relative path to the failed migrations directory
  def db_migration_failed_dirname
    'db/app_migrations/failed'
  end

  #
  # Run migrations in the current migration directory specified by #db_migration_dirname
  def run_migration
    return unless allow_migrations && db_migration_schema != DefaultMigrationSchema

    puts "Running migration from #{db_migration_dirname}"
    Rails.logger.info "Running migration from #{db_migration_dirname}"

    Timeout.timeout(30) do
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
    end

    self.class.tables_and_views_reset!

    true
  rescue StandardError => e
    FileUtils.mkdir_p db_migration_failed_dirname
    FileUtils.mv @do_migration, db_migration_failed_dirname
    raise FphsException, "Failed migration for path '#{db_migration_dirname}': #{e}\n#{e.backtrace.join("\n")}"
  rescue FphsException => e
    FileUtils.mkdir_p db_migration_failed_dirname
    FileUtils.mv @do_migration, db_migration_failed_dirname
    raise FphsException, "Failed migration for path '#{db_migration_dirname}': #{e}\n#{e.backtrace.join("\n")}"
  end

  #
  # Set a migration version timestamp
  def migration_version
    @migration_version ||= DateTime.now.to_i.to_s(36)
  end

  #
  # Run the appropriate generator script for this type of dynamic definition
  # @param [Class|String] type - class or class name of dynamic definition
  # @param [String|Symbol] mode
  # @return [String] - generated content
  def generator_script(type, mode = 'create')
    send("generator_script_#{type.to_s.underscore}", migration_version, mode)
  end

  def generator_script_activity_log(version, mode = 'create')
    cname = "#{mode}_#{table_name}_#{version}".camelize
    do_create_or_update = case mode
                          when 'create' then 'create_activity_log_tables'
                          when 'create_or_update' then 'create_or_update_activity_log_tables'
                          else
                            migration_update_table
                          end

    <<~CONTENT
      require 'active_record/migration/app_generator'
      class #{cname} < ActiveRecord::Migration[5.2]
        include ActiveRecord::Migration::AppGenerator

        def change
          self.belongs_to_model = '#{belongs_to_model}'
          #{migration_set_attribs}

          #{do_create_or_update}
          create_reference_views
          create_activity_log_trigger
        end
      end
    CONTENT
  end

  def generator_script_dynamic_model(version, mode = 'create')
    cname = "#{mode}_#{table_name}_#{version}".camelize

    table_or_view = view_sql ? 'view' : 'tables'
    do_create_or_update = if mode == 'create'
                            "create_dynamic_model_#{table_or_view}"
                          elsif mode == 'create_or_update'
                            "create_or_update_dynamic_model_#{table_or_view}"
                          elsif table_or_view == 'tables'
                            migration_update_table
                          else
                            migration_update_view
                          end

    <<~CONTENT
      require 'active_record/migration/app_generator'
      class #{cname} < ActiveRecord::Migration[5.2]
        include ActiveRecord::Migration::AppGenerator

        def change
          #{migration_set_attribs}

          #{do_create_or_update}
          #{table_or_view == 'tables' ? 'create_dynamic_model_trigger' : ''}
        end
      end
    CONTENT
  end

  def generator_script_external_identifier(version, mode = 'create')
    cname = "#{mode}_#{table_name}_#{version}".camelize
    ftype = (dynamic_def.alphanumeric ? 'string' : 'bigint')
    do_create_or_update = if mode == 'create'
                            "create_external_identifier_tables :#{dynamic_def.external_id_attribute}, :#{ftype}"
                          elsif mode == 'create_or_update'
                            "create_or_update_external_identifier_tables :#{dynamic_def.external_id_attribute}, :#{ftype}"
                          else
                            migration_update_table
                          end

    <<~CONTENT
      require 'active_record/migration/app_generator'
      class #{cname} < ActiveRecord::Migration[5.2]
        include ActiveRecord::Migration::AppGenerator

        def change
          #{migration_set_attribs}

          #{do_create_or_update}
          create_external_identifier_trigger :#{dynamic_def.external_id_attribute}
        end
      end
    CONTENT
  end

  private

  #
  # Content for a migration to create a schema
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
