# frozen_string_literal: true

module Dynamic
  #
  # Provide data dictionary functionality to dynamic models.
  class DataDictionary
    include OptionsHandler

    attr_accessor :dynamic_model, :fields

    def initialize(dynamic_model)
      self.dynamic_model = dynamic_model
      setup_fields_from_config
    end

    #
    # Set up the data dictionary variables using the dynamic model configuration
    def setup_fields_from_config
      self.fields = {}
      position = 0

      tcs = dynamic_model.table_columns
      tcs.each do |col|
        name = col.name
        next unless name.in?(column_variable_names)

        v = Dynamic::DynamicModelField.new(self, name, col.type, position: position)
        fields[name] = v
        position += 1
      end
    end

    #
    # A full list of variable names.
    # Uses the underlying table / view to get the database column definitions
    # for name and type. The core field names, such as id and master_id are excluded,
    # as are the placeholder_ and embedded_record_ prefixed fields, which do not
    # have underlying database columns.
    # @return [Array{String}]
    def column_variable_names
      return @column_variable_names if @column_variable_names

      dynamic_model.table_columns
                   .map(&:name)
                   .reject do |name|
                     name.in?(self.class.core_field_names) || name.index(/^embedded_report_|^placeholder_/)
                   end
    end

    #
    # Core field names to ignore when adding to the data dictionary
    # @return [Array{String}]
    def self.core_field_names
      %w[id user_id created_at updated_at disabled master_id]
    end

    #
    # Shortcut to the dynamic model options configuration set with the key
    # _data_dictionary: in the options text
    # @return [Hash] - setting values with symbol keys
    def dynamic_model_data_dictionary_config
      dynamic_model.data_dictionary || {}
    end

    #
    # Study this data dictionary is set to store to
    # @return [String] <description>
    def study
      dynamic_model_data_dictionary_config[:study]
    end

    #
    # Domain this data dictionary is set to store to
    # @return [String] <description>
    def domain
      dynamic_model_data_dictionary_config[:domain]
    end

    #
    # Set default values that will be used for all variables for this dynamic model.
    # Pulls from the dynamic model _data_dictionary: options and the definition fields
    # @return [Hash]
    def default_config
      return @default_config if @default_config

      dmdd = dynamic_model_data_dictionary_config
      @default_config = {
        study: study,
        domain: domain,
        source_name: dmdd[:source_name] || dynamic_model.name,
        source_type: dmdd[:source_type] || 'database',
        form_name: dmdd[:form_name],
        storage_type: 'database',
        db_or_fs: ActiveRecord::Base.connection_config[:database],
        schema_or_path: dynamic_model.schema_name,
        table_or_file: dynamic_model.table_name,
        is_derived_var: dmdd[:is_derived_var],
        owner_email: dmdd[:owner_email]
      }
    end

    #
    # Datadic::Variable records need to be updated to match the new definition
    # if there have been changes, additions or deletions
    def refresh_variables_records
      fields.each_value do |field|
        field.refresh_variable_record
      end

      add_overlay_info
    end

    #
    # After entering all the new or updated variables, perform a query to add in
    # metadata for derived variables, relating them to the underlying variables
    def add_overlay_info
      dv_opt = dynamic_model_data_dictionary_config[:derived_var_options]
      return unless dv_opt

      search_attr_values = {
        table_name: dynamic_model.table_name,
        study: study,
        name_regex_replace: dv_opt[:name_regex_replace],
        ref_source_type: dv_opt[:ref_source_type],
        ref_source_domain: dv_opt[:ref_source_domain]
      }

      sql = <<~END_SQL
        with matches as (
          select distinct
            derived.variable_name variable_name_d, refs.variable_name variable_name_r,
            refs.position, array[refs.id] rid, refs.label, refs.title, refs.section_id
          from ref_data.datadic_variables derived
          inner join ref_data.datadic_variables refs on
            refs.study = derived.study
            and coalesce(derived.is_derived_var, false)
            and not coalesce(refs.is_derived_var, false)
            and not coalesce(derived.disabled, false)
            and not coalesce(refs.disabled, false)
            and refs.table_or_file <> derived.table_or_file
            and (
              :ref_source_domain IS NULL AND refs.domain = derived.domain
              OR refs.domain = :ref_source_domain
            )
            and (
              :ref_source_type IS NULL OR
              refs.source_type = :ref_source_type
            )
            and (
              :name_regex_replace IS NULL OR
              regexp_replace(derived.variable_name, :name_regex_replace, '') = refs.variable_name
            )
            and derived.study = :study
            and derived.table_or_file =:table_name
          )
        update ref_data.datadic_variables dv
        set
          label = matches.label,
          position = matches.position,
          multi_derived_from_id = rid,
          title = matches.title,
          section_id = matches.section_id
        from matches
        where
          dv.study=:study
          and dv.table_or_file =:table_name
          and matches.variable_name_d = dv.variable_name
      END_SQL

      sql = ActiveRecord::Base.send(:sanitize_sql_for_conditions, [sql, search_attr_values])

      puts sql
      Admin::MigrationGenerator.connection.execute sql
    end
  end
end
