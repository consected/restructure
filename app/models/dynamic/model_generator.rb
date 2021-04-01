# frozen_string_literal: true

module Dynamic
  #
  # Supports the analysis of CSV files to discern their structure, then
  # create DynamicModels from them, including the underlying database table
  # matching the retrieved data.
  module ModelGenerator
    extend ActiveSupport::Concern

    DefaultCategory = 'dynamic'
    DefaultSchemaName = 'dynamic'

    included do
      # :field_types is a Hash of field_name => field_type values, where the field_name
      # is a symbol and field_type is a valid DB migration data type (also a symbol)
      attr_accessor :field_types
      attr_accessor :parent, :qualified_table_name, :category
    end

    #
    # Set up the key attributes for the generator. Typically called before
    # calling #create_dynamic_model or #dynamic_model
    # @param [Object] parent - parent object
    # @param [<Type>] qualified_table_name <description>
    # @return [<Type>] <description>
    def setup_generator(parent, qualified_table_name)
      self.parent = parent
      self.qualified_table_name = qualified_table_name
      self.category = DefaultCategory
    end

    #
    # Create an active dynamic model instance for storage of data records.
    # The table name can be qualified with a schema name, as <schema name>.<table name>
    # @param [String] table_name
    # @param [String] category - optional category, defaults to import
    # @return [DynamicModel]
    def create_dynamic_model
      schema_name, table_name = schema_and_table_name
      category = self.category || DefaultCategory

      name = table_name.singularize

      default_options = {
        default: {
          db_configs: db_configs,
          field_options: field_options,
          caption_before: caption_before
        }
      }.deep_stringify_keys!

      options = YAML.dump default_options

      if dynamic_model && dynamic_model.field_list != field_list
        dynamic_model.update! current_admin: current_admin,
                              field_list: field_list,
                              options: options,
                              allow_migrations: true
      else
        @dynamic_model = DynamicModel.create! current_admin: current_admin,
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
    # The dynamic model instance referenced by the table name in the instance attribute.
    # The table name can be qualified with a schema name, as <schema name>.<table name>
    # @param [true] no_check - don't check if the table is ready to use, otherwise return nil if it isn't
    # @return [DynamicModel]
    def dynamic_model(no_check: nil)
      return @dynamic_model if @dynamic_model

      schema_name, table_name = schema_and_table_name
      name = table_name.singularize

      @dynamic_model = DynamicModel.active.where(name: name, category: category, schema_name: schema_name).first
      return if !no_check && !dynamic_model_ready?

      @dynamic_model
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

    #
    # Check if the dynamic model for storage is ready to use,
    # both the DB table has been created and the class is defined
    # @return [true | nil]
    def dynamic_model_ready?
      return unless dynamic_model(no_check: true)
      return true if dynamic_model.implementation_class_defined?(Object, fail_without_exception: true)

      dynamic_model.generate_model if dynamic_model&.ready_to_generate?
      dynamic_model.implementation_class_defined?(Object, fail_without_exception: true)
    end

    private

    def current_admin
      return @current_admin if parent == self

      parent.current_admin
    end

    #
    # Return db_configs to summarize the real field types and enable definition
    # of a dynamic model
    # @return [Hash]
    def db_configs
      @db_configs = {}

      field_types.each do |field_name, field_type|
        @db_configs[field_name] = {
          type: field_type
        }
      end

      @db_configs
    end

    def field_options
      @field_options = {}

      field_types.each_key do |field_name|
        @field_options[field_name] = {
          no_downcase: no_downcase_field(field_name)
        }
      end

      @field_options
    end

    def caption_before
      @caption_before = {}
      return unless respond_to?(:fields) && fields

      fields.each_key do |name, config|
        @caption_before[name] = config[:caption]
      end

      @caption_before
    end

    #
    # Should a field prevent downcasing - override in the implementing class
    # @param [String | Symbol] field_name
    # @return [Boolean]
    def no_downcase_field(_field_name)
      false
    end

    #
    # List of field names to be used in a dynamic model field list
    # @return [String]
    def field_list
      @field_list ||= db_configs.keys.map(&:to_s).join(' ')
    end
  end
end
