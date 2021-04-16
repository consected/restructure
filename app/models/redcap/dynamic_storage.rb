# frozen_string_literal: true

module Redcap
  #
  # Handle the generation of dynamic models, and the underlying
  # migrations for tables and views
  class DynamicStorage
    include Dynamic::ModelGenerator
    DefaultCategory = 'redcap'
    DefaultSchemaName = 'redcap'

    attr_accessor :project_admin, :qualified_table_name, :category

    def initialize(project_admin, qualified_table_name)
      self.project_admin = project_admin
      self.qualified_table_name = qualified_table_name
      self.category = DefaultCategory
      setup_generator(project_admin, qualified_table_name)
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
      data_dictionary.all_retrievable_fields&.each do |field_name, field|
        @field_types[field_name] = field.field_type.database_type.to_s
      end

      @field_types
    end

    #
    # Should a field prevent downcasing
    # @param [String | Symbol] field_name
    # @return [Boolean]
    def no_downcase_field(_field_name)
      true
    end

    #
    # Add default user access control for the current admin
    # matching user
    def add_user_access_control
      admin = project_admin.current_admin
      return unless admin&.matching_user && dynamic_model
      return if admin.matching_user.has_access_to? :create, :table, dynamic_model.resource_name

      Admin::UserAccessControl.create!(app_type_id: admin.matching_user.app_type_id,
                                       resource_type: :table,
                                       resource_name: dynamic_model.resource_name,
                                       access: :create,
                                       disabled: false,
                                       current_admin: admin,
                                       user_id: admin.matching_user.id)
    end
  end
end
