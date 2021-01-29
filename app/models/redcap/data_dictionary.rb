# frozen_string_literal: true

module Redcap
  #
  # Build and manage dynamic models representing full REDCap data dictionaries
  # Since the data dictionary schema for different versions of REDCap may vary,
  # care has to be taken to keep the dynamic models in sync with the REDCap
  # metadata.
  # A DataDictionary record is added for each sync'd Redcap data dictionary,
  # allowing synchronizations to be tracked.
  class DataDictionary < Admin::AdminBase
    self.table_name = 'redcap_data_dictionaries'
    include AdminHandler

    belongs_to :redcap_project_admin, class_name: 'Redcap::ProjectAdmin'

    def retrieve_data_dictionary
      project_admin
    end
  end
end
