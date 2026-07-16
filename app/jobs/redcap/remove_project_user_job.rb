# frozen_string_literal: true

module Redcap
  #
  # Job to remove a user's access from a REDCap project in the background,
  # then refresh the locally stored project user list to reflect the removal.
  class RemoveProjectUserJob < RedcapJob
    #
    # Remove the user from the REDCap project via the API, then re-retrieve,
    # validate and store the refreshed list of project users.
    # @param [Redcap::ProjectAdmin] project_admin
    # @param [String] username
    # @return [Boolean] success
    def perform(project_admin, username)
      setup_with project_admin

      project_admin.api_client.remove_project_user(username: username)

      # Removing a user does not automatically refresh (or invalidate) the
      # REDCap API client's cached #project_users response (see
      # Redcap::ApiClient#remove_project_user), so force a reload here to
      # ensure the locally stored list reflects the removal.
      pu = Redcap::ProjectUsers.new project_admin
      pu.retrieve_validate_store(force_reload: true)
    rescue StandardError => e
      create_failure_record(e, 'remove project user job', project_admin)
      project_admin.update_status(:request_failed)

      raise
    end
  end
end
