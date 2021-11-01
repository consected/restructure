# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Handle the special redcap fields that are not listed in Redcap metadata export
    class SpecialFields
      #
      # Add a <form name>_timestamp field to the hash of fields in this form
      # if the project admin demands it
      # @param [Hash] fields <description>
      # @param [Redcap::DataDictionaries::Form] in_form
      def self.add_form_timestamp_field(fields, in_form)
        return unless in_form.data_dictionary.redcap_project_admin.records_request_options&.exportSurveyFields

        fields[form_timestamp_field_name(in_form)] = form_timestamp_field(in_form)
      end

      #
      # Add a <form name>_complete field to the hash of fields in this form
      # @param [Hash] fields <description>
      # @param [Redcap::DataDictionaries::Form] in_form
      def self.add_form_complete_field(fields, in_form)
        fields[form_complete_field_name(in_form)] = form_complete_field(in_form)
      end

      #
      # Add redcap_repeat_instrument and redcap_repeat_instance fields to the hash of fields in this form
      # @param [Hash] fields <description>
      # @param [Redcap::DataDictionary] in_form
      def self.add_repeat_instrument_fields(fields, data_dictionary)
        fields[:redcap_repeat_instrument] = repeat_instrument_field(data_dictionary)
        fields[:redcap_repeat_instance] = repeat_instance_field(data_dictionary)
      end

      #
      # Add a survey identifier field to the hash of fields in this form
      # @param [Hash] fields <description>
      # @param [Redcap::DataDictionary] in_form
      def self.add_survey_identifier_field(fields, data_dictionary)
        fields[survey_identifier_field_name] = survey_identifier_field(data_dictionary)
      end

      # The full record may have a redcap_survey_identifier field if project admin
      # attribute #records_request_options has exportSurveyFields: true
      # @return [Symbol]
      def self.survey_identifier_field_name
        :redcap_survey_identifier
      end

      #
      # A redcap_survey_identifier field representation to support the
      # identifer field if survey fields are requested
      # @param [Redcap::DataDictionary] data_dictionary
      # @return [Redcap::DataDictionaries::Field]
      def self.survey_identifier_field(data_dictionary)
        field_metadata = {
          field_name: survey_identifier_field_name,
          field_type: 'survey_identifier',
          text_validation_type_or_show_slider_number: 'string'
        }
        Field.new(nil, field_metadata, data_dictionary: data_dictionary)
      end

      # Each form may have a <form name>_timestamp field if project admin
      # attribute #records_request_options has exportSurveyFields: true
      # @param [Redcap::DataDictionaries::Form] form
      # @return [Symbol]
      def self.form_timestamp_field_name(form)
        "#{form.name}_timestamp".to_sym
      end

      #
      # A <form name>_complete field representation to support the timestamp
      # that Redcap adds for every form if survey fields are requested
      # @param [Redcap::DataDictionaries::Form] form
      # @return [Redcap::DataDictionaries::Field]
      def self.form_timestamp_field(form)
        field_metadata = {
          field_name: form_timestamp_field_name(form),
          field_type: 'form_timestamp',
          text_validation_type_or_show_slider_number: 'completed timestamp',
          field_annotation: 'Timestamp if completed, or NULL if source was empty or set to "[not completed]"'
        }
        Field.new(form, field_metadata, data_dictionary: form.data_dictionary)
      end

      #
      # Each form has an additional <form name>_complete field
      # Return the name for the requested form
      # @param [Redcap::DataDictionaries::Form] form
      # @return [Symbol]
      def self.form_complete_field_name(form)
        "#{form.name}_complete".to_sym
      end

      #
      # A <form name>_complete field representation to support the extra field
      # that Redcap adds for every form
      # @param [Redcap::DataDictionaries::Form] form
      # @return [Redcap::DataDictionaries::Field]
      def self.form_complete_field(form)
        field_metadata = {
          field_name: form_complete_field_name(form),
          field_type: 'form_complete',
          text_validation_type_or_show_slider_number: 'integer',
          field_annotation: 'Redcap values: 0 Incomplete, 1 Unverified, 2 Complete'
        }
        Field.new(form, field_metadata, data_dictionary: form.data_dictionary)
      end

      #
      # A redcap_repeat_instrument field representation to support the extra field
      # that Redcap adds for repeating instruments
      # @param [Redcap::DataDictionaries::Form] form
      # @return [Redcap::DataDictionary]
      def self.repeat_instrument_field(data_dictionary)
        field_metadata = {
          field_name: :redcap_repeat_instrument,
          field_type: 'repeat'
        }
        Field.new(nil, field_metadata, data_dictionary: data_dictionary)
      end

      #
      # A redcap_repeat_instrument field representation to support the extra field
      # that Redcap adds for repeating instruments
      # @param [Redcap::DataDictionaries::Form] form
      # @return [Redcap::DataDictionary]
      def self.repeat_instance_field(data_dictionary)
        field_metadata = {
          field_name: :redcap_repeat_instance,
          field_type: 'repeat'
        }
        Field.new(nil, field_metadata, data_dictionary: data_dictionary)
      end
    end
  end
end
