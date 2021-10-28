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
    # Set default values that will be used for all variables for this dynamic model.
    # Pulls from the dynamic model _data_dictionary: options and the definition fields
    # @return [Hash]
    def default_config
      return @default_config if @default_config

      dmdd = dynamic_model_data_dictionary_config
      @default_config = {
        study: dmdd[:study],
        domain: dmdd[:domain],
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
    end
  end
end
