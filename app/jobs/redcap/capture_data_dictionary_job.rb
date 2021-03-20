module Redcap
  class CaptureDataDictionaryJob < RedcapJob
    queue_as :default

    #
    # Capture the REDCap data dictionary "metadata" for the configured project admin.
    # The result is stored directly back to the data dictionary record.
    # @param [Redcap::DataDictionary] data_dictionary
    # @return [Boolean] success
    def perform(data_dictionary)
      unless data_dictionary.is_a? DataDictionary
        raise FphsException,
              'DataDictionary record required to capture current data dictionary job'
      end

      project_admin = data_dictionary.redcap_project_admin
      setup_with project_admin

      data_dictionary.current_admin ||= project_admin.admin
      m = project_admin.api_client.metadata

      raise FphsException, 'Metadata returned is not correct format' unless m.is_a? Array

      data_dictionary.update!(captured_metadata: m, field_count: m.length)
    rescue StandardError => e
      create_failure_record(e, 'capture data dictionary job', project_admin)

      raise
    end
  end
end
