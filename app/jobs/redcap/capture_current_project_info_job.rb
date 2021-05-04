module Redcap
  class CaptureCurrentProjectInfoJob < RedcapJob
    #
    # Capture the REDCap "project info" for the configured project admin.
    # The result is stored directly back to the project admin record.
    # @param [Redcap::ProjectAdmin] project_admin
    # @return [Boolean] success
    def perform(project_admin)
      setup_with project_admin
      pi = project_admin.api_client.project

      raise FphsException, 'Project info returned is not correct format' unless pi.is_a? Hash

      project_admin.update!(captured_project_info: pi)
    rescue StandardError => e
      create_failure_record(e, 'capture project info job', project_admin)
      project_admin.update_status(:request_failed)

      raise
    end
  end
end
