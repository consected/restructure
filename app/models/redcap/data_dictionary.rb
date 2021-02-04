# frozen_string_literal: true

module Redcap
  #
  # Build and manage dynamic models representing full REDCap data dictionaries
  # Since the data dictionary schema for different versions of REDCap may vary,
  # care has to be taken to keep the dynamic models in sync with the REDCap
  # metadata.
  # A DataDictionary record is added for each sync'd Redcap data dictionary,
  # allowing synchronizations to be tracked. Historical changes are retained in the
  # corresponding _history table.
  class DataDictionary < Admin::AdminBase
    self.table_name = 'redcap_data_dictionaries'
    include AdminHandler

    belongs_to :redcap_project_admin, class_name: 'Redcap::ProjectAdmin', foreign_key: :redcap_project_admin_id

    def forms
      return [] if captured_metadata.blank?

      @forms ||= DataDictionaries::Form.all_from self
    end

    #
    # The `name` of the project admin that this data dictionary belongs to
    # @return [<Type>] <description>
    def redcap_project_admin_name
      redcap_project_admin&.name
    end

    def captured_metadata
      ProjectClient.symbolize_result super
    end

    #
    # Store the data dictionary metadata from Redcap for future reference
    # Calls a delayed job to actually do the work
    def capture_data_dictionary
      Redcap::CaptureDataDictionaryJob.perform_later(self)
    end

    #
    # Shortcut to get a list of form names
    # @return [Array{Symbol}]
    def form_names
      forms&.keys
    end
  end
end
