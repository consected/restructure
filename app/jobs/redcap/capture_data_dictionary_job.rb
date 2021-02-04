module Redcap
  class CaptureDataDictionaryJob < ApplicationJob
    queue_as :default

    #
    # Capture the REDCap data dictionary "meatadata" for the configured project admin.
    # The result is stored directly back to the data dictionary record.
    # @param [Redcap::ProjectAdmin] project_admin
    # @param [Redcap::DataDictionary] data_dictionary
    # @return [Boolean] success
    def perform(data_dictionary)
      unless data_dictionary.is_a? DataDictionary
        raise FphsException,
              'DataDictionary record required to capture current data dictionary job'
      end

      project_admin = data_dictionary.redcap_project_admin

      # Use the original admin as the current admin
      project_admin.current_admin ||= project_admin.admin
      data_dictionary.current_admin ||= project_admin.admin
      m = project_admin.project_client.metadata

      raise FphsException, 'Metadata returned is not correct format' unless m.is_a? Array

      data_dictionary.update!(captured_metadata: m, field_count: m.length)
    end
  end
end
