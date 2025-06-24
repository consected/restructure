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
    # @param [true | false] summary_fields - include the summary fields (such as the chosen arrays for checkboxes)
    # @return [Hash{Symbol => Field}]
    def all_retrievable_fields(summary_fields: false)
      return unless captured_metadata.present?

      summary_fields &&= redcap_project_admin.data_options.add_multi_choice_summary_fields
      all_rf = Redcap::DataDictionaries::Form.all_retrievable_fields(self, summary_fields:)

      records_request_options = redcap_project_admin.records_request_options
      special_fields = Redcap::DataDictionaries::SpecialFields
      if records_request_options&.exportSurveyFields
        special_fields.add_survey_identifier_field(all_rf, self)
        handle_integer_survey_field(all_rf, special_fields)
      end
      special_fields.add_repeat_instrument_fields(all_rf, self) if redcap_project_admin.repeating_instruments?
      special_fields.add_defined_event_field(all_rf, self) if redcap_project_admin.is_longitudinal?

      all_rf
    end

    #
    # If we are going to join on the default redcap_survey_identifier, we need it to be an integer.
    # Add a separate integer version of this field to be stored alongside the original string field.
    def handle_integer_survey_field(all_retrievable_fields, special_fields)
      fk_eid = redcap_project_admin.data_options.associate_master_through_external_identifer
      return unless fk_eid

      # Check the configuration is set to another name. If not set, it defaults to the integer survey id field name
      fname = redcap_project_admin.integer_survey_identifier_field
      add_fk_id = redcap_project_admin.associate_master_through_external_id_fkey_name
      return unless add_fk_id == fname

      # We are using the integer survey id field. Add it.
      special_fields.add_integer_survey_identifier_field(all_retrievable_fields, self)
    end

    #
    # The sequential record_id field is not a fixed name. Get the first field from the data dictionary
    # @return [Symbol]
    def record_id_field
      all_fields.keys.first
    end

    #
    # For repeating instruments and longitudinal events, extra fields are required in addition to the #record_id_field
    # to uniquely identify a record
    # @return [Array{Symbol} | nil] <description>
    def record_id_extra_fields
      return %i[redcap_repeat_instrument redcap_repeat_instance] if redcap_project_admin.repeating_instruments?
      return %i[redcap_event_name] if redcap_project_admin.is_longitudinal?

      nil
    end

    #
    # Provide a 'version' string to allow us to check for changes.
    # We have to sort the data by key, since it is arbitrary the order that is returned
    # @return [String]
    def captured_metadata_digest
      txt = captured_metadata.map { |i| i.sort { |a, b| b.first <=> a.first } }.to_s
      Digest::MD5.hexdigest(txt)
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
