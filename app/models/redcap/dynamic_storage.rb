# frozen_string_literal: true

module Redcap
  #
  # Handle the generation of dynamic models, and the underlying
  # migrations for tables and views
  class DynamicStorage
    include Dynamic::ModelGenerator

    ExtraFieldTypes = {
      disabled: 'boolean',
      master_id: 'integer'
    }.freeze

    attr_accessor :project_admin, :qualified_table_name, :category

    def self.default_category
      'redcap'
    end

    def self.default_schema_name
      return 'redcap' if Rails.env.production?

      'redcap_test'
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
    # @param [Boolean] ignore_cache - force pull from REDCap, bypassing cache
    # @param [Boolean] retrieve_all - ignore export_only_updated_records setting and retrieve all records
    def request_records(ignore_cache: false, retrieve_all: false, request_source: nil)
      unless dynamic_model
        raise FphsException,
              'dynamic model has not been set up'
      end

      dr = Redcap::DataRecords.new(project_admin, dynamic_model_class_name, request_source:)
      dr.request_records(ignore_cache:, retrieve_all:)
    end

    #
    # Return field_types hash to summarize the real field types and enable definition
    # of a dynamic model
    # @return [Hash]
    def field_types
      @field_types = {}
      all_retrievable_fields(summary_fields: true)&.each do |field_name, field|
        @field_types[field_name] = field.field_type.database_type.to_s
      end

      extra_fields&.each do |ef|
        ef = ef.to_sym
        ft = ExtraFieldTypes[ef] || 'string'
        @field_types[ef] = ft.to_s
      end

      @field_types
    end

    #
    # Return a hash of all fields, with a value true if they are to be represented as an array
    # in the database. Used alongside #field_types a full definition of the field can be made
    # for migrations.
    # @return [Hash]
    def array_fields
      return @array_fields if @array_fields

      @array_fields = {}
      all_retrievable_fields(summary_fields: true)&.each do |field_name, field|
        @array_fields[field_name] = field.field_type.database_array?
      end

      extra_fields&.each do |ef|
        ef = ef.to_sym
        # Assume it is an array if it isn't one of the predefined extra fields
        ft = !ExtraFieldTypes.keys.include?(ef)
        @array_fields[ef] = ft
      end

      @array_fields
    end

    #
    # Configuration of fields used by the model generator.
    # This is a mix of real database fields and additional "marker" fields such as
    # placeholders and embedded reports. This set is derived from the Redcap
    # project fields, and includes every "field" that appears in the final dynamic model.
    # @param [Symbol | false] option_type - optional option type to return fields for
    # @return [Hash{String => Hash}]
    def fields(option_type: false)
      @fields_for_option_type ||= {}
      return @fields_for_option_type[option_type] if @fields_for_option_type[option_type]

      @fields_for_option_type[option_type] = @fields = {}
      @show_if_condition_strings = {}

      process_fields = if option_type == false
                         data_dictionary.all_fields
                       else
                         data_dictionary.forms[option_type].fields
                       end

      process_fields.each do |field_name, field|
        choices = nil

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

        if project_admin.data_options.add_multi_choice_summary_fields && field.multiple_choice?
          # Create a "chosen array" if the project configuration requires a summary field
          # to capture all of the multiple choice values in one place
          # But only do this if the number of choices is greater than 1, since we don't want this
          # for standalone checkboxes
          choices ||= field.field_choices&.choices(plain_text: true, rails_format: true)

          @fields[field.chosen_array_field_name] = {
            caption: field.label,
            edit_options: choices.to_h,
            edit_field_type: "tag_select_#{field.chosen_array_field_name}"
          }
          # NOTE: we use a full tag_select_... field name to ensure the values can be looked up correctly
          # This requires display of the field to look for
          # "name_starts_with_redcap_tag_select" rather than an exact match
          # on the redcap_tag_select field type.
        end

        ccf = field.field_choices&.choices_plain_text
        next unless ccf.present?

        # Create a field for each multiple choice value
        ccf.each do |arr|
          fname = arr.first
          label = arr.last
          ccffn = field.choice_field_name(fname)
          @fields[ccffn] = {
            label:
          }
          @show_if_condition_strings[ccffn.to_sym] = bl_condition_string if bl_condition_string.present?
        end
      end

      unless option_type
        extras = {}
        data_dictionary.merge_special_project_fields!(extras)
        data_dictionary.merge_all_form_complete_fields!(extras)

        extras.each_key do |field_name|
          @fields[field_name.to_s] = {}
        end

      end

      # Add a disabled field if one is not present and we need to disable deleted records
      @fields['disabled'] ||= { label: 'disabled' } if project_admin.data_options.handle_deleted_records == 'disabled'

      @fields.stringify_keys
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
      field_names = all_fields.keys
      before_field = 'submit'

      field_names.reverse_each do |field_name|
        field = all_fields[field_name]

        if all_retrievable_fields.key?(field_name)
          # This has a real column in the database, so can be
          # used to reference the position of a preceding field
          # No placeholder is required for the caption
          before_field = field_name
        else
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

    def all_retrievable_fields(summary_fields: false)
      data_dictionary.all_retrievable_fields(summary_fields:)
    end

    #
    # Dfeine the extra fields to be included in a dynamic model, based on project
    # configurations. This includes `disabled`, `master_id` and array fields summarizing
    # chosen values for multiple choice (checkbox) fields.
    # @return [<Type>] <description>
    def extra_fields
      return @extra_fields if @extra_fields

      @extra_fields = []
      @extra_fields << 'disabled' if project_admin.disable_deleted_records?
      @extra_fields << 'master_id' if project_admin.data_options.set_master_id_using_association

      return @extra_fields unless project_admin.data_options.add_multi_choice_summary_fields

      data_dictionary.all_fields.each_value do |field|
        next unless field.multiple_choice?

        # Create a "chosen array" if the project configuration requires a summary field
        # to capture all of the multiple choice values in one place
        # But only do this if the number of choices is greater than 1, since we don't want this
        # for standalone checkboxes
        @extra_fields << field.chosen_array_field_name.to_s
      end

      @extra_fields
    end

    #
    # Override default field options creation method, to include field_type and alt_options
    # @return [Hash]
    def field_options
      @field_options = {}

      # Prevent all fields from automatically downcasing values when persisted
      field_types.each_key do |field_name|
        @field_options[field_name] = {
          no_downcase: no_downcase_field(field_name)
        }
      end

      fields&.each do |field_name, config|
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

      # If we don't have a redcap_repeat_instrument field, set a blank preset value for option_type
      # to set the value to the form name of the completed form.
      unless fields['redcap_repeat_instrument']
        bpv = ''
        test = '#if'
        option_types.each do |ot|
          bpv = "#{bpv}{{#{test} #{ot}_complete}}#{ot}"
          test = 'else if'
        end
        bpv = "#{bpv}{{/if}}"

        @field_options['option_type'] = {
          active_value: bpv
        }
      end

      @field_options
    end

    def option_type_attr_name
      fields['redcap_repeat_instrument'] ? 'redcap_repeat_instrument' : 'option_type'
    end

    #
    # Returns a Hash of dynamic model field names (symbols)
    # keyed by option type (Redcap form name)
    # @return [Hash{Symbol => Array}]
    def field_names_by_option_type
      fbot = {}
      option_types.each do |ot|
        fbot[ot] = fields(option_type: ot).symbolize_keys.keys
      end
      fbot
    end

    #
    # List of option types, which are the Redcap form names
    # @return [Array{Symbol}]
    def option_types
      data_dictionary.forms.keys
    end

    #
    # Indicate that all fields should be listed when generating option types
    # so that show_if in fields from other forms work correctly.
    # The value is :hide_external_fields to indicate the fields from other option types
    # should be hidden
    # @return [Symbol]
    def include_all_fields_in_option_types
      :hide_external_fields
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
    # Specifies the "<category> <name>" part of the @library string to add automatically when
    # generating the dynamic model
    # @return [String]
    def prefix_config_library
      project_admin.data_options.prefix_dynamic_model_config_library
    end

    #
    # Specifies the external identifier resource name from associate_master_through_external_identifer
    def associate_master_through_external_id_resource_name
      project_admin.associate_master_through_external_id_resource_name
    end

    #
    # Specifies the foreign key name from associate_master_through_external_identifer
    def associate_master_through_external_id_fkey_name
      project_admin.associate_master_through_external_id_fkey_name
    end

    #
    # Add default user access control for the current admin
    # matching user
    def add_user_access_control
      admin = project_admin.current_admin

      unless admin&.matching_user && dynamic_model
        Rails.logger.warn "Not adding user access control to dynamic model for project #{project_admin.id}: #{admin&.matching_user} && #{dynamic_model}"
        return
      end

      if admin.matching_user.has_access_to? :create, :table, dynamic_model.resource_name
        Rails.logger.warn "Not adding user access control to dynamic model for project #{project_admin.id} - no access to #{dynamic_model.resource_name}"
        return
      end

      Admin::UserAccessControl.create!(app_type_id: admin.matching_user.app_type_id,
                                       resource_type: :table,
                                       resource_name: dynamic_model.resource_name,
                                       access: :create,
                                       disabled: false,
                                       current_admin: admin,
                                       user_id: admin.matching_user.id)
    end

    def dynamic_model_name
      project_admin.name
    end
  end
end
