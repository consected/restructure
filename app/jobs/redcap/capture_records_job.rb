# frozen_string_literal: true

module Redcap
  #
  # Job to capture the REDCap project's records
  class CaptureRecordsJob < RedcapJob
    queue_as :redcap

    #
    # Capture the REDCap records for the configured project admin.
    # The records are stored directly to the specified model.
    # The result (number of created, updated, matched, error items) is stored to a Redcap::ClientRequest
    # @param [Redcap::ProjectAdmin] project_admin
    # @param [String] class_name
    # @return [Boolean] success
    def perform(project_admin, class_name)
      setup_with project_admin

      unless project_admin&.dynamic_storage&.dynamic_model_ready?
        raise FphsException, "Data Model not ready for table: #{project_admin.dynamic_model_table}"
      end

      dr = Redcap::DataRecords.new(project_admin, class_name)
      dr.retrieve_validate_store
    rescue StandardError => e
      create_failure_record(e, 'capture records job', project_admin)
      raise
    end
  end
end
