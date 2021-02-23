# frozen_string_literal: true

module Redcap
  #
  # Handle the generation of dynamic models, and the underlying
  # migrations for tables and views
  class DynamicStorage
    DefaultCategory = 'redcap'
    DefaultSchemaName = 'redcap'

    attr_accessor :project_admin, :qualified_table_name, :category

    def initialize(project_admin, qualified_table_name)
      self.project_admin = project_admin
      self.qualified_table_name = qualified_table_name
      self.category = DefaultCategory
      super()
    end

    def data_dictionary
      project_admin.redcap_data_dictionary
    end

    #
    # Request a background job retrieve records and save them to the specified model
    # @see Redcap::CaptureRecordsJob#perform_later
    # @param [Redcap::ProjectAdmin] project_admin
    def request_records
      unless dynamic_model
        raise FphsException,
              'dynamic model has not been set up'
      end

      dr = Redcap::DataRecords.new(project_admin, dynamic_model_class_name)
      dr.request_records
    end

    #
    # Return db_configs to summarize the real field types and enable definition
    # of a dynamic model
    # @return [Hash]
    def db_configs
      @db_configs ||= {}

      data_dictionary.all_retrievable_fields.each do |field_name, field|
        @db_configs[field_name] = {
          type: field.field_type.database_type.to_s
        }
      end

      @db_configs
    end

    def field_options
      @field_options ||= {}

      data_dictionary.all_retrievable_fields.each do |field_name, _field|
        @field_options[field_name] = {
          no_downcase: true
        }
      end

      @field_options
    end

    #
    # List of field names to be used in a dynamic model field list
    # @return [String]
    def field_list
      @field_list ||= db_configs.keys.map(&:to_s).join(' ')
    end

    #
    # Create an active dynamic model instance for storage of REDcap data records.
    # The table name can be qualified with a schema name, as <schema name>.<table name>
    # @param [String] table_name
    # @param [String] category - optional category, defaults to redcap
    # @return [DynamicModel]
    def create_dynamic_model(category: DefaultCategory)
      schema_name, table_name = schema_and_table_name

      name = table_name.singularize

      default_options = {
        default: {
          db_configs: db_configs,
          field_options: field_options
        }
      }.deep_stringify_keys

      options = YAML.dump default_options

      if dynamic_model && dynamic_model.field_list != field_list
        dynamic_model.update! current_admin: project_admin.current_admin,
                              field_list: field_list,
                              options: options,
                              allow_migrations: true
      else
        @dynamic_model = DynamicModel.create! current_admin: project_admin.current_admin,
                                              name: name,
                                              table_name: table_name,
                                              primary_key_name: :id,
                                              foreign_key_name: nil,
                                              category: category,
                                              field_list: field_list,
                                              options: options,
                                              schema_name: schema_name,
                                              allow_migrations: true
      end

      # Force delayed job to update with the new definition
      AppControl.restart_delayed_job

      @dynamic_model
    end

    #
    # The dynamic model instance referenced by the table name.
    # The table name can be qualified with a schema name, as <schema name>.<table name>
    # @param [String | Symbol] table_name
    # @param [String] category - optional category, defaults to redcap
    # @return [DynamicModel]
    def dynamic_model
      return @dynamic_model if @dynamic_model

      schema_name, table_name = schema_and_table_name
      name = table_name.singularize

      @dynamic_model = DynamicModel.active.where(name: name, category: category, schema_name: schema_name).first
    end

    #
    # Split the qualified table name into schema and table, if possible,
    # otherwise return with the default schema name
    # @return [<Type>] <description>
    def schema_and_table_name
      if qualified_table_name.include? '.'
        schema_name, table_name = qualified_table_name.split('.', 2)
      else
        table_name = qualified_table_name
        schema_name = DefaultSchemaName
      end
      [schema_name, table_name]
    end

    #
    # Get the implementation class name for the dynamic model,
    # which is used for storage of records
    # @return [String]
    def dynamic_model_class_name
      dynamic_model.implementation_class.name
    end

    def dynamic_model_ready?
      dynamic_model&.implementation_class_defined?(Object, fail_without_exception: true)
    end
  end
end
