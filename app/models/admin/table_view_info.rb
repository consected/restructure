# frozen_string_literal: true

#
# Details of a table or view in a schema visible to the app.
# Used by the Tables tab of the reference data admin page, and the Table / View panel
# of dynamic definition admin pages, so both show the same information.
# Names are only queried once they match a table or view the app can see, so they are never
# used to build SQL directly.
class Admin::TableViewInfo
  attr_reader :schema_name, :table_name

  # @param [String] schema_name
  # @param [String] table_name
  def initialize(schema_name:, table_name:)
    @schema_name = schema_name.to_s
    @table_name = table_name.to_s
  end

  # Tables and views in the schemas visible to the app, for the table / view search on the Tables tab
  # @return [Array<Hash{Symbol => String | Boolean}>]
  def self.search_items
    view_keys = Admin::MigrationGenerator.views.to_set { |v| [v['schema_name'], v['table_name']] }

    Admin::MigrationGenerator.tables_and_views.map do |t|
      schema_name = t['schema_name']
      table_name = t['table_name']
      {
        label: "#{schema_name}.#{table_name}",
        schema: schema_name,
        table: table_name,
        object_type: view_keys.include?([schema_name, table_name]) ? 'view' : 'table',
        history: table_name.end_with?('_history')
      }
    end
  end

  # Dynamic definitions (dynamic models, activity logs and external identifiers) that use a table or view
  # in a schema, keyed by table name. These are read from the database, so every definition is found,
  # whether or not its class has been loaded into this process.
  # A definition without a schema name uses the schema its table is found in, as the database resolves it.
  # @param [String] schema_name
  # @return [Hash{String => DynamicModel | ActivityLog | ExternalIdentifier}]
  def self.dynamic_definitions_in_schema(schema_name)
    schema_hash = Admin::MigrationGenerator.table_schema_hash
    definitions = [DynamicModel, ActivityLog, ExternalIdentifier].flat_map { |klass| klass.all.to_a }

    # Enabled definitions take precedence over disabled ones that use the same table
    definitions.sort_by { |definition| definition.disabled ? 1 : 0 }.each_with_object({}) do |definition, res|
      table = definition.table_name
      definition_schema = definition.schema_name.presence || schema_hash[table]
      res[table] ||= definition if definition_schema == schema_name
    end
  end

  # @return [true | false]
  def exists?
    return @exists if defined?(@exists)

    @exists = Admin::MigrationGenerator.table_or_view_exists_in_schema?(table_name, schema_name).present?
  end

  # @return [:table | :view | nil]
  def object_type
    return unless exists?

    view? ? :view : :table
  end

  # @return [true | false]
  def view?
    exists? && Admin::MigrationGenerator.view_in_schema?(table_name, schema_name)
  end

  # @return [String | nil] the DDL for a view
  def view_definition
    return unless view?

    Admin::MigrationGenerator.view_definition(schema_name, table_name)
  end

  # @return [Array<ActiveRecord::ConnectionAdapters::Column>]
  def columns
    return [] unless exists?

    Admin::MigrationGenerator.connection.columns("#{schema_name}.#{table_name}")
  end

  # @return [String | nil]
  def table_comment
    Admin::MigrationGenerator.table_comment(table_name, schema_name) if exists?
  end

  # @param [String] column_name
  # @return [String | nil]
  def column_comment(column_name)
    comment = Admin::MigrationGenerator.column_comments.find do |cc|
      cc['schema_name'] == schema_name && cc['table_name'] == table_name && cc['column_name'] == column_name
    end
    comment&.dig('column_comment')
  end

  # @param [String] column_name
  # @return [String | nil] the referenced table and column, for a foreign key column
  def column_foreign_key(column_name)
    fk = Admin::MigrationGenerator.foreign_keys.find do |cfk|
      cfk['source_schema'] == schema_name && cfk['source_table'] == table_name && cfk['source_column'] == column_name
    end
    "#{fk['target_schema']}.#{fk['target_table']} (#{fk['target_column']})" if fk
  end
end
