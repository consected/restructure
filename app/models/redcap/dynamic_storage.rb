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
      @show_if_condition_strings = {}
      all_retrievable_fields = data_dictionary.all_retrievable_fields

      data_dictionary.all_fields.each do |field_name, field|
        fn = "placeholder_#{field_name}__title"
        if placeholder_fields.value?(fn)
          @fields[fn] = {
            caption: field.title
          }
          use_fn = fn
        end

        fn = "placeholder_#{field_name}"
        if placeholder_fields.value?(fn)
          @fields[fn] = {
            caption: field.label
          }
          use_fn = fn
        elsif all_retrievable_fields.key?(field_name)
          @fields[field_name] = {
            caption: field.label
          }
          use_fn = field_name

          ### Handle field types and alt options

          mvt = field.field_type.model_variable_type
          @fields[field_name][:edit_field_type] = mvt if mvt

          choices = field.field_choices.choices(plain_text: true, rails_format: true)
          @fields[field_name][:edit_options] = choices.to_h if choices

        end

        bl = field.branching_logic
        bl_condition_string = bl&.condition_string
        @show_if_condition_strings[use_fn.to_sym] = bl_condition_string if bl_condition_string.present?

        next unless field.field_type.name == :checkbox

        ccf = field.field_choices&.choices_plain_text
        next unless ccf.present?

        ccf.each do |arr|
          fname = arr.first
          label = arr.last
          ccffn = field.choice_field_name(fname)
          @fields[ccffn] = {
            label: label
          }
          @show_if_condition_strings[ccffn.to_sym] = bl_condition_string if bl_condition_string.present?
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
    # Override default field options creation method, to include field_type and alt_options
    # @return [Hash]
    def field_options
      @field_options = {}

      field_types.each_key do |field_name|
        @field_options[field_name] = {
          no_downcase: no_downcase_field(field_name)
        }
      end

      if respond_to?(:fields) && fields
        fields.each do |field_name, config|
          edit_field_type = config_value(config, :edit_field_type)
          next unless edit_field_type

          @field_options[field_name].merge! edit_as: {
            field_type: "redcap_#{edit_field_type}"
          }

          edit_options = config_value(config, :edit_options)
          next unless edit_options

          @field_options[field_name][:edit_as].merge! alt_options: edit_options
        end

        # Set the record id field to be displayed fixed.
        record_id_fn = field_types.keys.first
        @field_options[record_id_fn][:edit_as] = {
          field_type: "fixed_#{record_id_fn}"
        }

      end

      @field_options
    end

    #
    # Override default show_if_condition_strings method, to branching logic strings
    # @return [Hash]
    def show_if_condition_strings
      fields # initializes the hash
      @show_if_condition_strings
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
