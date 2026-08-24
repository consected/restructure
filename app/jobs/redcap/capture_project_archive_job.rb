# frozen_string_literal: true

module Redcap
  #
  # Job to capture a project archive XML file in the background
  class CaptureProjectArchiveJob < RedcapJob
    #
    # Download the XML project archive, optionally without project data, and store it to the file_store container.
    # The stored file record is returned if successful.
    # @param [Redcap::ProjectAdmin] project_admin
    # @param [Boolean] definition_only - whether to omit project data
    # @return [NfsStore::Manage::StoredFile]
    def perform(project_admin, definition_only: false)
      setup_with project_admin

      container = project_admin.file_store
      raise FphsException, 'Project archive not downloaded - no file store set up' unless container

      temp_file = project_admin.api_client.project_archive(definition_only:)
      path = "#{project_admin.dynamic_model_table}/#{definition_only ? 'project-definition' : 'project'}"

      dt = DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')
      filename = "#{definition_only ? 'definition' : 'archive'}-#{dt}.xml"

      NfsStore::Import.import_file(container.id,
                                   filename,
                                   temp_file.path,
                                   project_admin.job_user,
                                   path:,
                                   replace: true)
    rescue StandardError => e
      create_failure_record(e, 'capture project archive job', project_admin)
      project_admin.update_status(:request_failed)

      raise
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end
end
