# frozen_string_literal: true

module Redcap
  #
  # Job to capture a list of data collection instruments in the background
  class ExportLogsJob < RedcapJob
    #
    # Download the list of data collection instruments.
    # @param [Redcap::ProjectAdmin] project_admin
    # @return [Boolean] success
    def perform(project_admin, filter: nil)
      setup_with project_admin

      el = Redcap::ExportLogs.new(project_admin)
      el.retrieve_validate_store(filter: filter)
    rescue StandardError => e
      create_failure_record(e, 'export logs job', project_admin)
      project_admin.update_status(:request_failed)

      raise
    end
  end
end
