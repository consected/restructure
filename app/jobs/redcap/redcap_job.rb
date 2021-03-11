# frozen_string_literal: true

module Redcap
  #
  # Skeleton job for REDCap retrievals.
  class RedcapJob < ApplicationJob
    queue_as :redcap

    def setup_with(project_admin, current_admin: nil)
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
      Redcap::ClientRequest.create current_admin: project_admin.current_admin,
                                   action: action,
                                   server_url: project_admin.server_url,
                                   name: project_admin.name,
                                   redcap_project_admin: project_admin,
                                   result: { error: e, backtrace: e.backtrace[0..20].join("\n") }
    end
  end
end
