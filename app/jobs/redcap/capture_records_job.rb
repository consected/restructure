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
    # @param [Hash] opts
    # @option opts [Boolean] :ignore_cache - force pull from REDCap, bypassing cache
    # @option opts [Boolean] :retrieve_all - ignore export_only_updated_records setting and retrieve all records
    # @option opts [Boolean] :verify_file_fields - check that each file field's underlying stored file exists,
    #                                              and retry capture for any missing files.
    # @return [Boolean] success
    # NOTE: opts must be a plain Hash default arg (not Ruby keyword args) so that delayed_job can
    # deserialize and splat arguments correctly in Ruby 3. Active Job serializes kwargs as a symbol-keyed
    # Hash; when the worker calls perform(*arguments), Ruby 3 passes that hash as a positional arg and
    # will NOT auto-convert it to keyword arguments, causing ArgumentError.
    def perform(project_admin, class_name, opts = {})
      ignore_cache = opts.fetch(:ignore_cache, false)
      retrieve_all = opts.fetch(:retrieve_all, false)
      verify_file_fields = opts.fetch(:verify_file_fields, false)

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
