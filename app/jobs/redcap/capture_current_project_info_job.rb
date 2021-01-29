module Redcap
  class CaptureCurrentProjectInfoJob < ApplicationJob
    queue_as :default

    def perform(project_admin)
      unless project_admin.is_a? ProjectAdmin
        raise FphsException,
              'ProjectAdmin record required to capture current project info job'
      end

      project_admin.current_admin = project_admin.admin
      pi = project_admin.project_client.project

      raise FphsException, 'Project info returned is not correct format' unless pi.is_a? Hash

      project_admin.update!(captured_project_info: pi)
    end
  end
end
