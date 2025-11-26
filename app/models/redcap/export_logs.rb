# frozen_string_literal: true

module Redcap
  #
  # Capture logged events associated with a project
  class ExportLogs # < Admin::AdminBase
    # self.table_name = 'redcap_export_logs'
    # include AdminHandler

    attr_accessor :project_admin, :records, :log_events, :errors, :current_admin, :filter

    def initialize(project_admin)
      self.project_admin = project_admin
      self.log_events = []
      self.errors = []
      self.current_admin = project_admin.admin
      self.project_admin.current_admin = current_admin
    end

    # belongs_to :redcap_project_admin,
    #            class_name: 'Redcap::ProjectAdmin',
    #            foreign_key: :redcap_project_admin_id,
    #            inverse_of: :redcap_export_logs

    #
    # Capture the event logs from Redcap
    # Calls a delayed job to actually do the work
    def self.export_logs(project_admin, filter = nil)
      jobclass = Redcap::ExportLogsJob
      jobs = ProjectAdmin.existing_jobs(jobclass, project_admin)
      return if jobs.count > 0

      jobclass.perform_later(project_admin, filter:)
      project_admin.record_job_request('setup job: export logs')
    end

    #
    # Immediately retrieve, validate and store the records from REDCap.
    # This is only intended to be called from a background job.
    def retrieve_validate_store(filter: nil)
      self.filter = filter || {}
      retrieve
      validate
      store
    end

    #
    # Immediately retrieve records from REDCap.
    # This is only intended to be called from a background job.
    # @return [Array{Hash}]
    def retrieve
      self.records = project_admin.api_client.export_logs(
        record_id: filter[:record_id],
        begin_time: filter[:begin_time],
        end_time: filter[:end_time],
        log_type: filter[:log_type]
      )
    end

    #
    # Perform validations on the records returned
    # We choose to fail with an exception for these, since any of them
    # represent bad data retrieved from Redcap, which could indicate corruption
    # of the data, which should not make it to the local database
    def validate
      unless records.is_a? Array
        raise FphsException, "Redcap::ProjectUser did not return an array: #{records.class.name}"
      end

      return unless records.first

      return true if records.first.is_a? Hash

      raise FphsException, "Redcap::ProjectUser did not return a hash as first item: #{records.first.class.name}"
    end

    #
    # Store the results.
    # TBD on how to best store these.
    # Error will appear in #errors
    # IDs of created items will appear in #created_usernames
    # IDs of updated items will appear in #updated_usernames
    # IDs of disabled items will appear in #disabled_usernames
    def store
      result = {
        filter:,
        log_events: records.length
      }

      temp_file = Tempfile.new('redcap-logs')
      temp_file.write(records.to_json)
      temp_file.close
      path = "#{project_admin.dynamic_model_table}/export-logs/"
      filename = "redcap-logs-#{filter[:record_id]}-#{filter[:log_type]}-#{filter[:begin_time]}-#{filter[:end_time]}.json"
      container = project_admin.file_store

      res = NfsStore::Import.import_file(container.id,
                                         filename,
                                         temp_file.path,
                                         project_admin.current_user,
                                         path:,
                                         replace: true)

      Rails.logger.debug "Redcap::ExportLogs stored log events:\n#{records}"

      project_admin.record_job_request('store export logs', result:)
    rescue Exception => e
      # We rescue Exception rather than SndardError, since file errors inherit from Exception
      msg = "Failed to retrieve or store REDCap export log for #{filter} - with user: #{project_admin.current_user.email}.\n#{e}"
      Rails.logger.warn msg
      errors << { filter:, errors: { export_logs: msg }, action: :export_logs }
      raise
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end
end
