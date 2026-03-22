# frozen_string_literal: true

module Redcap
  #
  # Job to capture a project archive XML file in the background
  class CaptureProjectUsersJob < RedcapJob
    #
    # Download the list of project users.
    # @param [Redcap::ProjectAdmin] project_admin
    # @return [Boolean] success
    def perform(project_admin)
      setup_with project_admin

      pu = Redcap::ProjectUsers.new project_admin
      pu.retrieve_validate_store
    rescue StandardError => e
      create_failure_record(e, 'capture project users job', project_admin)
      project_admin.update_status(:request_failed)

      raise
    end
  end
end
