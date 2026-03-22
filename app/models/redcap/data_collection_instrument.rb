# frozen_string_literal: true

module Redcap
  #
  # Capture and store the names of data collection instruments associated with a project
  class DataCollectionInstrument < Admin::AdminBase
    self.table_name = 'redcap_data_collection_instruments'
    include AdminHandler

    belongs_to :redcap_project_admin,
               class_name: 'Redcap::ProjectAdmin',
               foreign_key: :redcap_project_admin_id,
               inverse_of: :redcap_data_collection_instruments

    #
    # Store the data collection instrument list from Redcap for future reference
    # Calls a delayed job to actually do the work
    def self.capture_data_collection_instruments(project_admin)
      jobclass = Redcap::CaptureDataCollectionInstrumentsJob
      jobs = ProjectAdmin.existing_jobs(jobclass, project_admin)
      return if jobs.count > 0

      Redcap::CaptureDataCollectionInstrumentsJob.perform_later(project_admin)
      project_admin.record_job_request('setup job: instruments')
    end

    #
    # Immediately retrieve records from REDCap, then store new and changed records
    # This is only intended to be called from a background job.
    # @param [Redcap::ProjectAdmin] project_admin
    # @return [Array{Hash}] records returned by client request
    def self.retrieve_and_store(project_admin)
      records = project_admin.api_client.instruments

      item_ids = []

      transaction do
        records.each do |record|
          name = record[:instrument_name]
          label = record[:instrument_label]

          res = project_admin.redcap_data_collection_instruments.active.find_or_create_by(name:)
          res.update!(label:, current_admin: project_admin.current_admin) if res.label != label
          item_ids << res.id
        end

        project_admin.redcap_data_collection_instruments.active.where.not(id: item_ids).update_all(disabled: true)
      end

      records
    end
  end
end
