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

    def setup_fields_from_config
      self.fields = {}
      position = 0

      tcs = dynamic_model.table_columns
      tcs.each do |col|
        name = col.name
        next unless name.in?(column_variable_names)

        v = Dynamic::DatadicVariable.new(self, name, col.type, position: position)
        fields[name] = v
        position += 1
      end
    end

    def column_variable_names
      return @column_variable_names if @column_variable_names

      dynamic_model.table_columns
                   .map(&:name)
                   .reject do |name|
                     name.in?(self.class.core_field_names) || name.index(/^embedded_report_|^placeholder_/)
                   end
    end

    def self.core_field_names
      %w[id user_id created_at updated_at disabled master_id]
    end

    def dynamic_model_data_dictionary_config
      dynamic_model.data_dictionary || {}
    end

    def source_default_config
      return @source_default_config if @source_default_config

      dmdd = dynamic_model_data_dictionary_config

      @source_default_config = {
        study: dmdd[:study],
        source_name: dmdd[:source_name] || dynamic_model.name,
        source_type: dmdd[:source_type] || 'database',
        form_name: dmdd[:form_name],
        domain: dmdd[:domain] || dynamic_model.table_comments&.dig(:table),
        storage_type: 'database',
        db_or_fs: ActiveRecord::Base.connection_config[:database],
        schema_or_path: dynamic_model.schema_name,
        table_or_file: dynamic_model.table_name
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
