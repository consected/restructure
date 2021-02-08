module Redcap
  class CaptureCurrentProjectInfoJob < ApplicationJob
    queue_as :default

    #
    # Capture the REDCap "project info" for the configured project admin.
    # The result is stored directly back to the project admin record.
    # @param [Redcap::ProjectAdmin] project_admin
    # @return [Boolean] success
    def perform(project_admin)
      unless project_admin.is_a? ProjectAdmin
        raise FphsException,
              'ProjectAdmin record required to capture current project info job'
      end

      # Use the original admin as the current admin
      project_admin.current_admin = project_admin.admin
      pi = project_admin.project_client.project

      raise FphsException, 'Project info returned is not correct format' unless pi.is_a? Hash

      project_admin.update!(captured_project_info: pi)
    end
  end
end
