module Redcap
  #
  # Job to capture the REDCap project's records on a schedule
  # Schedule with:
  #
  #     Redcap::RecurringPullTask.schedule! run_every: 1.hour,
  #                                         job_matching_param: 'schedule_id',
  #                                         schedule_id: project_admin.id
  #
  # If schedule is reissued with a matching schedule_id, preexisting schedules will be unscheduled first
  class RecurringPullTask < ApplicationRecurringJob
    queue :redcap

    include RedcapJobHandler

    #
    # Capture the REDCap records for the configured project admin.
    # The records are stored directly to the specified model.
    # The result (number of created, updated, matched, error items) is stored to a Redcap::ClientRequest
    # @param [Redcap::ProjectAdmin] project_admin
    # @param [String] class_name
    # @return [Boolean] success
    def perform
      puts recurring_job_data
      project_admin = GlobalID::Locator.locate recurring_job_data[:project_admin]
      class_name = recurring_job_data[:class_name]

      setup_with project_admin

      unless project_admin&.dynamic_model_ready?
        raise FphsException, "Data Model not ready for table: #{project_admin.dynamic_model_table}"
      end

      unless project_admin&.storage_and_model_fields_match?
        status_already_set = true
        project_admin.update_status(:changes_detected)
        raise FphsException, "Data Model table fields don't match the data dictionary: " \
                             "#{project_admin.dynamic_model_table}"
      end

      # Schedule an update of the project users in the background
      project_admin.capture_project_users

      dr = Redcap::DataRecords.new(project_admin, class_name)
      dr.retrieve_validate_store
      project_admin.update_status(:scheduled_run_successful)
    rescue StandardError => e
      create_failure_record(e, 'recurring capture records job', project_admin)
      project_admin.update_status(:scheduled_run_failed) unless status_already_set
      raise
    end
  end
end
