# frozen_string_literal: true

module Redcap
  #
  # Handle the generation of dynamic models, and the underlying
  # migrations for tables and views
  class DynamicStorage
    DefaultCategory = 'redcap'
    DefaultSchemaName = 'redcap'

    include Dynamic::ModelGenerator

    attr_accessor :project_admin, :qualified_table_name, :category

    def initialize(project_admin, qualified_table_name)
      self.project_admin = project_admin
      self.qualified_table_name = qualified_table_name
      self.category = DefaultCategory
      super
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
    # Return field_types hash to summarize the real field types and enable definition
    # of a dynamic model
    # @return [Hash]
    def field_types
      @field_types = {}
      data_dictionary.all_retrievable_fields.each do |field_name, field|
        @field_types[field_name] = field.field_type.database_type.to_s
      end

      @field_types
    end
  end
end
