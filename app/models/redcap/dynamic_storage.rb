# frozen_string_literal: true

module Redcap
  #
  # Handle the generation of dynamic models, and the underlying
  # migrations for tables and views
  class DynamicStorage
    include Dynamic::ModelGenerator

    attr_accessor :project_admin, :qualified_table_name, :category

    def self.default_category
      'redcap'
    end

    def self.default_schema_name
      'redcap'
    end

    def initialize(project_admin, qualified_table_name)
      self.project_admin = project_admin
      self.qualified_table_name = qualified_table_name
      self.category = self.class.default_category
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
      data_dictionary&.all_retrievable_fields&.each do |field_name, field|
        @field_types[field_name] = field.field_type.database_type.to_s
      end

      @field_types
    end

    #
    # Configuration of fields used by the model generator
    # @return [Hash{String => String}]
    def fields
      return @fields if @fields

      @fields = {}
      all_retrievable_fields = data_dictionary.all_retrievable_fields

      data_dictionary.all_fields.each do |field_name, field|
        if placeholder_fields.value?("placeholder_#{field_name}__title")
          @fields["placeholder_#{field_name}__title"] = {
            caption: field.title
          }
        end

        if placeholder_fields.value?("placeholder_#{field_name}")
          @fields["placeholder_#{field_name}"] = {
            caption: field.label
          }
        elsif all_retrievable_fields.key?(field_name)
          @fields[field_name] = {
            caption: field.label
          }

          ### Handle field types and alt options

          mvt = field.field_type.model_variable_type
          @fields[field_name][:edit_field_type] = mvt if mvt

          choices = field.field_choices.choices(plain_text: true, rails_format: true)
          @fields[field_name][:edit_options] = choices.to_h if choices

        end

        next unless field.field_type.name == :checkbox

        ccf = field.field_choices&.choices_plain_text
        next unless ccf.present?

        ccf.each do |arr|
          fname = arr.first
          label = arr.last
          @fields[field.choice_field_name(fname)] = {
            label: label
          }
        end
      end

      @fields
    end

    #
    # Hash of placholder fields, where the key is the field it appears before,
    # and the value is the placeholder field name
    # @return [Hash{String => String}]
    def placeholder_fields
      return @placeholder_fields if @placeholder_fields

      @placeholder_fields = {}
      return {} unless data_dictionary&.all_fields

      all_fields = data_dictionary.all_fields
      all_retrievable_fields = data_dictionary.all_retrievable_fields

      field_names = all_fields.keys
      before_field = 'submit'

      field_names.reverse_each do |field_name|
        field = all_fields[field_name]

        if !all_retrievable_fields.key?(field_name)
          # This does not have a column in the database
          # We add a placeholder field for the caption
          # keeping the placeholder field name as a reference
          # for the preceding field if it needs a reference
          # for its position

          # Multiple choice checkboxes are a special case, and we
          # need to look up the first actual field, for this
          # placeholder to appear in front of
          if field.field_type.name == :checkbox
            ccf = field.field_choices&.choices_values&.first
            before_field = field.choice_field_name(ccf)
          end

          phname = "placeholder_#{field_name}"
          @placeholder_fields[before_field.to_s] = phname
          before_field = phname
        else
          # This has a real column in the database, so can be#
          # used to reference the position of a preceding field
          # No placeholder is required for the caption
          before_field = field_name
        end

        next unless field.title.present?

        # For a field that also has a title defined, add the title as a placeholder
        # field above the current field.
        phname = "placeholder_#{field_name}__title"
        @placeholder_fields[before_field.to_s] = phname
        # The preceding field will reference the new placeholder field if needed
        before_field = phname
      end

      @placeholder_fields
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
