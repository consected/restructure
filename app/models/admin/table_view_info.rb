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
