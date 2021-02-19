# frozen_string_literal: true

module Redcap
  class CaptureRecordsJob < ApplicationJob
    queue_as :redcap

    #
    # Capture the REDCap records for the configured project admin.
    # The records are stored directly to the specified model.
    # The result (number of created, updated, matched, error items) is stored to a Redcap::ClientRequest
    # @param [Redcap::ProjectAdmin] project_admin
    # @param [String] class_name
    # @return [Boolean] success
    def perform(project_admin, class_name)
      unless project_admin.is_a? ProjectAdmin
        raise FphsException,
              'ProjectAdmin record required to capture current project info job'
      end

      # Use the original admin as the current admin
      project_admin.current_admin ||= project_admin.admin

      dr = Redcap::DataRecords.new(project_admin, class_name)
      dr.retrieve_validate_store
    rescue StandardError => e
      Redcap::ClientRequest.create current_admin: project_admin.current_admin,
                                   action: 'capture records job',
                                   server_url: project_admin.server_url,
                                   name: project_admin.name,
                                   redcap_project_admin: project_admin,
                                   result: { error: e, backtrace: e.backtrace[0..7].join("\n") }
      raise
    end
  end
end
