# frozen_string_literal: true

module Redcap
  #
  # Job to capture the REDCap project's records (manual pull)
  class CaptureRecordsJob < RedcapJob
    #
    # Capture the REDCap records for the configured project admin.
    # The records are stored directly to the specified model.
    # The result (number of created, updated, matched, error items) is stored to a Redcap::ClientRequest
    # @param [Redcap::ProjectAdmin] project_admin
    # @param [String] class_name
    # @param [Boolean] ignore_cache - force pull from REDCap, bypassing cache
    # @param [Boolean] retrieve_all - ignore export_only_updated_records setting and retrieve all records
    # @param [Boolean] verify_file_fields - check that each file field's underlying stored file exists,
    #                                       and retry capture for any missing files.
    # @return [Boolean] success
    def perform(project_admin, class_name, ignore_cache: false, retrieve_all: false, verify_file_fields: false)
      setup_with project_admin

      unless project_admin&.dynamic_model_ready?
        raise FphsException, "Data Model not ready for table: #{project_admin.dynamic_model_table}"
      end

      unless project_admin&.model_has_all_fields_for_storage?
        status_already_set = true
        project_admin.update_status(:changes_detected)
        raise FphsException, "Data Model table fields don't match the data dictionary: " \
                             "#{project_admin.dynamic_model_table}"
      end

      dr = Redcap::DataRecords.new(project_admin, class_name,
                                   is_manual_pull: true,
                                   verify_file_fields:)
      dr.retrieve_validate_store(ignore_cache:, retrieve_all:)
      project_admin.update_status(:manual_run_successful)
    rescue StandardError => e
      create_failure_record(e, 'capture records job', project_admin)
      project_admin.update_status(:manual_run_failed) unless status_already_set
      raise
    end
  end
end
