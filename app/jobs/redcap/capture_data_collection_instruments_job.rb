# frozen_string_literal: true

module Redcap
  #
  # Job to capture a list of data collection instruments in the background
  class CaptureDataCollectionInstrumentsJob < RedcapJob
    #
    # Download the list of data collection instruments.
    # @param [Redcap::ProjectAdmin] project_admin
    # @return [Boolean] success
    def perform(project_admin)
      setup_with project_admin

      Redcap::DataCollectionInstrument.retrieve_and_store project_admin
    rescue StandardError => e
      create_failure_record(e, 'capture data collection instrument job', project_admin)
      project_admin.update_status(:request_failed)

      raise
    end
  end
end
