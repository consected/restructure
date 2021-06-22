# frozen_string_literal: true

module Redcap
  #
  # Build and manage dynamic models representing full REDCap data dictionaries
  # Since the data dictionary schema for different versions of REDCap may vary,
  # care has to be taken to keep the dynamic models in sync with the REDCap
  # metadata.
  # A DataDictionary record is added for each sync'd Redcap data dictionary,
  # allowing synchronizations to be tracked. Historical changes are retained in the
  # corresponding _history table.
  class DataDictionary < Admin::AdminBase
    self.table_name = 'redcap_data_dictionaries'
    include AdminHandler

    belongs_to :redcap_project_admin,
               class_name: 'Redcap::ProjectAdmin',
               foreign_key: :redcap_project_admin_id,
               inverse_of: :redcap_data_dictionary

    after_save :refresh_variables_records, if: -> { captured_metadata }
    after_save :refresh_choices_records, if: -> { captured_metadata }

    #
    # All form representations for this database
    # @return [Hash] { <form_name>: Redcap::DataDictionaries::Form }
    def forms
      return [] if captured_metadata.blank?

      @forms ||= DataDictionaries::Form.all_from self
    end

    #
    # The `name` of the project admin that this data dictionary belongs to
    # @return [<Type>] <description>
    def redcap_project_admin_name
      redcap_project_admin&.name
    end

    def captured_metadata
      Redcap::ApiClient.symbolize_result super
    end

    #
    # Store the data dictionary metadata from Redcap for future reference
    # Calls a delayed job to actually do the work
    def capture_data_dictionary
      jobclass = Redcap::CaptureDataDictionaryJob
      jobs = ProjectAdmin.existing_jobs(jobclass, self)
      return if jobs.count > 0

      Redcap::CaptureDataDictionaryJob.perform_later(self)
      redcap_project_admin.record_job_request('setup job: metadata')
    end

    #
    # Shortcut to get a list of form names
    # @return [Array{Symbol}]
    def form_names
      forms&.keys
    end

    #
    # The source name for data items is the server domain name
    # @return [String] <description>
    def source_name
      @source_name ||= URI.parse(redcap_project_admin.server_url).host
    end

    #
    # Shortcut to the study name
    # @return [String]
    def study
      redcap_project_admin.study
    end

    #
    # Get an hash of all fields from all forms
    # @return [Hash]
    def all_fields
      return unless captured_metadata.present?
      return @all_fields if @all_fields

      @all_fields = {}
      forms.each do |_k, form|
        @all_fields.merge! form.fields
      end

      @all_fields
    end

    #
    # Get an hash of all fields from all forms with a specific field type
    # @param [Symbol] type_name
    # @return [Hash]
    def all_fields_of_type(type_name)
      all_fields.filter { |_field_name, field| field.field_type.name == type_name }
    end

    #
    # Get a Hash of all fields that should be returned in a REDCap record retrieval, which takes into account
    # the checkbox choice fields that are persisted individually and the additional survey fields if the
    # project admin has configured them to be returned.
    # The configuration is based on the latest retrieved REDCap metadata data dictionary.
    # Checkbox choice fields, with checkbox_field___choice style appear in the results, and the
    # base checkbox_field without the suffix does not appear, since it is not a field actually retrieved.
    # @return [Hash{Symbol => Field}]
    def all_retrievable_fields
      return unless captured_metadata.present?

      all_rf = Redcap::DataDictionaries::Form.all_retrievable_fields(self)

      records_request_options = redcap_project_admin.records_request_options
      if records_request_options&.exportSurveyFields
        # Handle the redcap_survey_identifier field
        f = Redcap::DataDictionaries::SpecialFields
        all_rf[f.survey_identifier_field_name] = f.survey_identifier_field(self)
      end

      all_rf
    end

    #
    # The sequential record_id field is not a fixed name. Get the first field from the data dictionary
    # @return [Symbol]
    def record_id_field
      all_fields.keys.first
    end

    private

    #
    # Datadic::Variable records need to be updated to match the new metadata
    # if there have been changes, additions or deletions
    def refresh_variables_records
      return unless captured_metadata

      forms.each do |_k, form|
        form.fields.each do |_k, field|
          field.refresh_variable_record
        end

        Redcap::DataDictionaries::SpecialFields.form_complete_field(form).refresh_variable_record
      end

      # Trigger updates on the project admin to ensure updates there if needed
      redcap_project_admin.update!(updated_at: DateTime.now)
    end

    #
    # Datadic::Choice records need to be updated to match the new metadata
    # if there have been changes to dropdown, radio or checkbox fields
    def refresh_choices_records
      return unless captured_metadata

      forms.each do |_k, form|
        form.fields.each do |_k, field|
          field.field_choices.refresh_choices_records
        end
      end
    end
  end
end
