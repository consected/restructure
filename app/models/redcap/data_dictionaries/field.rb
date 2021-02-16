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
                    :valid_min, :valid_max, :is_identifier

      def initialize(form, field_metadata)
        super()

        self.form = form
        self.def_metadata = field_metadata.dup
        self.name = field_metadata[:field_name].to_sym
        self.label = field_metadata[:field_label]
        self.label_note = field_metadata[:field_note]
        self.annotation = field_metadata[:field_annotation]
        self.is_required = field_metadata[:required_field] == 'y'

        self.valid_min = field_metadata[:text_validation_min]
        self.valid_max = field_metadata[:text_validation_max]
        self.is_identifier = field_metadata[:identifier] == 'y'
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

      def to_s
        name.to_s
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
      # Get an Hash of all field representations, keyed with the symbolized field name
      # for a form
      # @param [Form] form
      # @return [Hash{Symbol => Field}]
      def self.all_from(in_form)
        fields_metadata = in_form.def_metadata
        return unless fields_metadata.present?

        fields = {}

        fields_metadata.each do |field_metadata|
          form = Field.new(in_form, field_metadata)
          fields[form.name] = form
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

        new_set
      end

      #
      # A "checkbox" type field is actually represented in record data with multiple fields,
      # named '<base_field_name>___<choice_value[n]>'
      # something like 'smoketime___after', 'smoketime___before', 'smoketime___never'
      # @return [Array{Symbol} | nil] - array of record field names or nil if not a checkbox type field
      def checkbox_choice_fields
        return nil unless field_type.name == :checkbox

        field_choices.choices_values.map { |v| "#{name}___#{v}".to_sym }
      end

      #
      # Shortcut to the owning data dictionary
      # @return [Redcap::DataDictionary]
      def data_dictionary
        form.data_dictionary
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
