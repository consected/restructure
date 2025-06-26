module Reports
  # Handle data reference when running reports
  class DataReference
    ValidSqlSubstitutions = %i[table_name schema_name table_fields id_field
                               col_names resource_model user_can master_route_prefix current_user].freeze

    attr_accessor(*ValidSqlSubstitutions, :runner, :substitution_data)

    def initialize(runner)
      self.runner = runner
      self.current_user = runner.current_user
      self.substitution_data = {}
      self.user_can = {}
      self.master_route_prefix = "''"
    end

    #
    # Initialize with options
    # @param [Hash | nil] options
    def init(options = nil)
      options ||= {}

      (ValidSqlSubstitutions & options.keys).each do |a|
        send("#{a}=", options[a])
      end

      table_exists = Admin::MigrationGenerator.table_or_view_exists_in_schema?(table_name, schema_name)
      raise FphsException, 'invalid table name' unless table_exists

      self.col_names = Admin::MigrationGenerator.table_column_names(table_name)
      pk = Admin::MigrationGenerator.find_primary_key(schema_name, table_name)
      self.id_field = if pk
                        pk
                      elsif col_names.include?('id')
                        'id'
                      else
                        col_names.first
                      end

      self.resource_model = Resources::Models.find_by(table_name: table_name)
      if resource_model

        self.master_route_prefix = "'/masters/' || master_id" if resource_model.base_master_segment
        %i[access edit update create].each do |access|
          user_can[access] = resource_model.model.allows_user_access_to?(runner.current_user, access)
        end
      end

      ValidSqlSubstitutions.each do |a|
        substitution_data[a] = send(a)
      end
    end

    #
    # Make substitutions for {{table_name}} {{schema_name}} {{table_fields}} etc
    # Currently, table_fields must be '*'
    # @param [String] sql - source SQL
    # @return [String] the original SQL if data reference is not defined, or a copy of the string with substitutions
    def sql_substitutions(sql)
      if sql_needs_substitution(sql) && !specified?
        raise FphsException,
              'data reference table_name or schema_name expected but not provided'
      end

      return sql unless specified?

      raise FphsException, 'table fields incorrect' unless table_fields == '*'

      Formatter::Substitution.substitute(sql, data: substitution_data, ignore_missing: true)
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
