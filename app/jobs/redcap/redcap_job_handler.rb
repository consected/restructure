# frozen_string_literal: true

# Common handler for Recap jobs, setting up the project admin record related
# to the job and handling error reporting
module Redcap
  module RedcapJobHandler
    def setup_with(project_admin)
      # puts "Setup project admin in Job: #{self}"
      unless project_admin.is_a? ProjectAdmin
        raise FphsException,
              'ProjectAdmin record required for Redcap jobs'
      end

      # Use the supplied admin if requested or original admin
      project_admin.current_admin = project_admin.job_admin
      project_admin.current_user = project_admin.job_user
      project_admin.current_user.app_type = project_admin.job_app_type
      project_admin.in_background_job = true

      raise FphsException, 'RedcapJobHandler: job admin is not set' unless project_admin.current_admin.is_a?(Admin)
      raise FphsException, 'RedcapJobHandler: job user is not set' unless project_admin.current_user.is_a?(User)

      unless project_admin.current_user.app_type.is_a?(Admin::AppType)
        raise FphsException,
              'RedcapJobHandler: job user app type is not set'
      end

      Rails.logger.info 'Running REDCap job with - ' \
                        "admin: #{project_admin.current_admin.email} - " \
                        "user #{project_admin.current_user.email} - " \
                        "app type: #{project_admin.current_user.app_type.name}"
    end

    def create_failure_record(exception, action, project_admin)
      error = exception
      backtrace = error.short_string_backtrace
      if error.respond_to? :response
        response = error.response
        result = { error:, response:, backtrace: }
      else
        result = { error:, backtrace: }
      end
      project_admin.record_job_request(action, result:)

    rescue StandardError => e
      msg = "Failed to create failure record for job: #{self} - #{exception} - #{action} - #{response}"
      Rails.logger.error msg
      Rails.logger.error(backtrace)
    end
  end
end
