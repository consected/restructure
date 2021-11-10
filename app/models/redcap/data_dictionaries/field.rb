# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Field representation of the field definition for the data dictionaries
    # This is retrieved from a REDCap JSON structure, where each field is a Hash:
    # {
    #   "field_name": 'age',
    #   "form_name": 'test',
    #   "section_header": '',
    #   "field_type": 'text',
    #   "field_label": 'Age',
    #   "select_choices_or_calculations": '',
    #   "field_note": '(in years)',
    #   "text_validation_type_or_show_slider_number": 'integer',
    #   "text_validation_min": '1',
    #   "text_validation_max": '120',
    #   "identifier": '',
    #   "branching_logic": '',
    #   "required_field": 'y',
    #   "custom_alignment": '',
    #   "question_number": '',
    #   "matrix_group_name": '',
    #   "matrix_ranking": '',
    #   "field_annotation": 'a private comment not seen by users'
    # }
    class Field
      attr_accessor :def_metadata, :form, :name, :label, :label_note, :annotation, :is_required,
                    :valid_type, :valid_min, :valid_max, :is_identifier,
                    :storage_type, :db_or_fs, :schema_or_path, :table_or_file,
                    :position, :section, :sub_section, :title, :form_name, :study,
                    :is_derived_var, :owner_email

      attr_writer :data_dictionary

      #
      # Set up a field representation from metadata. By default a form the field belongs to is expected,
      # but some fields do not belong to a form, so a data_dictionary can be passed as an option instead
      # @param [Redcap::DataDictionaries::Form] form - nil if the field does not belong to a form
      # @param [Hash] field_metadata
      # @param [Redcap::DataDictionary] data_dictionary - required if form is nil
      # @param [Integer] position
      def initialize(form, field_metadata, data_dictionary:, position: nil, section: nil, sub_section: nil)
        super()

        self.form = form
        self.form_name = form&.name

        self.data_dictionary = data_dictionary
        self.study = data_dictionary.study

        self.def_metadata = field_metadata.dup
        self.name = field_metadata[:field_name].to_sym
        self.title = field_metadata[:section_header]
        self.label = field_metadata[:field_label]
        self.label_note = field_metadata[:field_note]
        self.annotation = field_metadata[:field_annotation]
        self.is_required = field_metadata[:required_field] == 'y'

        self.valid_type = field_metadata[:text_validation_type_or_show_slider_number]
        self.valid_min = field_metadata[:text_validation_min]
        self.valid_max = field_metadata[:text_validation_max]
        self.is_identifier = field_metadata[:identifier] == 'y'

        self.storage_type = 'database'
        self.db_or_fs = ActiveRecord::Base.connection_config[:database]
        self.schema_or_path, self.table_or_file = schema_and_table_name
        self.position = position
        self.section = section
        self.sub_section = sub_section
      end

      #
      # Get the field type representation of for this field
      # @return [Redcap::DataDictionary::FieldType]
      def field_type
        @field_type ||= FieldType.new(self, def_metadata[:field_type])
      end

      #
      # Get the field choices representation of for this field
      # @return [Redcap::DataDictionary::FieldChoices]
      def field_choices
        @field_choices ||= FieldChoices.new(self)
      end

      #
      # Get the field choices as plain text for this field
      # @return [Array{String}]
      def field_choices_plain_text
        field_choices.choices(plain_text: true)
      end

      def to_s
        name.to_s
      end

      #
      # Quick way to get a plain text title
      # @return [String]
      def title_plain
        Redcap::Utilities.html_to_plain_text title
      end

      #
      # Quick way to get a plain text label
      # @return [String]
      def label_plain
        Redcap::Utilities.html_to_plain_text label
      end

      #
      # Quick way to get a plain text label note
      # @return [String]
      def label_note_plain
        Redcap::Utilities.html_to_plain_text label_note
      end

      #
      # Quick way to get the field presentation type
      # @return [String]
      def presentation_type
        field_type.presentation_type
      end

      #
      # Quick way to get the default variable type for fields
      # @return [String]
      def default_variable_type
        field_type.default_variable_type
      end

      #
      # Get an Hash of all field representations, keyed with the symbolized field name
      # for a form.
      # Each field has a position in the form, incrementing from 0.
      # If a descriptive field is found, its position will be saved and the following
      # regular fields will refer to its position in the @section attribute.
      # A descriptive field itself never has a position.
      # @param [Form] form
      # @return [Hash{Symbol => Field}]
      def self.all_from(in_form)
        fields_metadata = in_form.def_metadata
        return unless fields_metadata.present?

        fields = {}
        position = 0
        section = nil

        fields_metadata.each do |field_metadata|
          section = nil if field_metadata[:field_type] == 'descriptive'
          field = Field.new(in_form, field_metadata,
                            position: position,
                            section: section,
                            data_dictionary: in_form.data_dictionary)
          fields[field.name] = field
          section = field.name if field_metadata[:field_type] == 'descriptive'
          position += 1
        end

        fields
      end

      #
      # Get a Hash of all fields that should be returned in a REDCap record retrieval, which takes into account
      # the checkbox choice fields that are persisted individually. This is based on the latest retrieved REDCap
      # metadata data dictionary.
      # Checkbox choice fields, with checkbox_field___choice style appear in the results, and the
      # base checkbox_field without the suffix does not appear, since it is not a field actually retrieved.
      # @param [Form] form
      # @return [Hash{Symbol => Field}]
      def self.all_retrievable_fields(in_form)
        new_set = {}

        all_from(in_form).each do |field_name, field|
          next if field.field_type.name == :descriptive

          ccf = field.checkbox_choice_fields
          if ccf
            ccf.each do |c|
              field.field_type.name = :checkbox_choice
              new_set[c] = field
            end
            next
          end

          new_set[field_name] = field
        end

        SpecialFields.add_form_complete_field(new_set, in_form)
        SpecialFields.add_form_timestamp_field(new_set, in_form)

        new_set
      end

      #
      # A "checkbox" type field is actually represented in record data with multiple fields,
      # named '<base_field_name>___<choice_value[n]>'
      # something like 'smoketime___after', 'smoketime___before', 'smoketime___never'
      # @return [Array{Symbol} | nil] - array of record field names or nil if not a checkbox type field
      def checkbox_choice_fields
        return nil unless field_type.name == :checkbox

        field_choices.choices_values.map { |v| choice_field_name(v).to_sym }
      end

      #
      # Generate the field name for a checkbox choice from the
      # root field name and the choice value
      # @param [String] value
      # @return [String]
      def choice_field_name(value)
        "#{name}___#{value}"
      end

      #
      # Shortcut to the owning data dictionary
      # @return [Redcap::DataDictionary]
      def data_dictionary
        @data_dictionary ||= form.data_dictionary
      end

      alias owner data_dictionary

      def schema_and_table_name
        data_dictionary.redcap_project_admin.dynamic_storage&.schema_and_table_name || [nil, nil]
      end

      #
      # The source name for data items is the server domain name
      # @return [String] <description>
      def source_name
        data_dictionary.source_name
      end

      #
      # Refresh variable records (Datadic::Variable) based on
      # current definition.
      # @see Redcap::DataDictionaries::FieldDatadicVariables#refresh_variable_record
      def refresh_variable_record
        FieldDatadicVariable.new(self).refresh_variable_record
      end
    end
  end
end
