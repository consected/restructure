module Reports
  # Handle data reference when running reports
  class DataReference
    attr_accessor :table_name, :schema_name, :table_fields, :runner

    def initialize(runner)
      self.runner = runner
    end

    #
    # Initialize with options
    # @param [Hash | nil] options
    def init(options = nil)
      return unless options

      %i[table_name schema_name table_fields].each do |a|
        send("#{a}=", options[a])
      end
    end

    #
    # Make substitutions for {{table_name}} {{schema_name}} and {{table_fields}}
    # Currently, table_fields must be '*'
    # @param [String] sql - source SQL
    # @return [String] the original SQL if data reference is not defined, or a copy of the string with substitutions
    def sql_substitutions(sql)
      if sql_needs_substitution(sql) && !specified?
        raise FphsException,
              'data reference table_name or schema_name expected but not provided'
      end

      return sql unless specified?

      table_exists = Admin::MigrationGenerator.table_or_view_exists_in_schema?(table_name, schema_name)
      raise FphsException, 'invalid table name' unless table_exists

      raise FphsException, 'table fields incorrect' unless table_fields == '*'

      sql = sql.gsub('{{table_name}}', table_name)
      sql = sql.gsub('{{schema_name}}', schema_name)
      sql.gsub('{{table_fields}}', table_fields)
    end

    #
    # Check if the sql has substitution tags
    # @param [String] sql
    # @return [Boolean]
    def sql_needs_substitution(sql)
      sql.include?('{{table_name}}') || sql.include?('{{schema_name}}')
    end

    #
    # Has a data reference been specified for use?
    # @return [Boolean]
    def specified?
      table_name.present? && schema_name.present?
    end
  end
end
