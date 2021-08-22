# frozen_string_literal: true

# Common handler for Recap jobs, setting up the project admin record related
# to the job and handling error reporting
module Redcap
  module RedcapJobHandler
    def setup_with(project_admin, current_admin: nil)
      # puts "Setup project admin in Job: #{self}"
      unless project_admin.is_a? ProjectAdmin
        raise FphsException,
              'ProjectAdmin record required for Redcap jobs'
      end

      # Use the supplied admin if requested or original admin
      project_admin.current_admin ||= current_admin || project_admin.admin
      project_admin.current_user ||= current_admin.matching_user
    end

    def create_failure_record(exception, action, project_admin)
      e = exception
      result = { error: e, backtrace: e.backtrace[0..20].join("\n") }
      project_admin.record_job_request(action, result: result)
    end
  end
end
