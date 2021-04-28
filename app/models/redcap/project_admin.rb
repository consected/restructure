# frozen_string_literal: true

module Redcap
  #
  # Representation of a Redcap project as configured by an administrator
  # This is retrieved from a REDCap JSON structure, a Hash:
  # {
  #   "project_id": '77',
  #   "project_title": 'q2_demo',
  #   "creation_time": '2019-01-17 14:02:14',
  #   "production_time": '',
  #   "in_production": '0',
  #   "project_language": 'English',
  #   "purpose": '2',
  #   "purpose_other": '5',
  #   "project_notes": 'Demo project for the Q2 survey (03/15/2019)',
  #   "custom_record_label": '[redcap_survey_identifier]',
  #   "secondary_unique_field": '',
  #   "is_longitudinal": 0,
  #   "surveys_enabled": '1',
  #   "scheduling_enabled": '0',
  #   "record_autonumbering_enabled": '1',
  #   "randomization_enabled": '0',
  #   "ddp_enabled": '0',
  #   "project_irb_number": '',
  #   "project_grant_number": '',
  #   "project_pi_firstname": '',
  #   "project_pi_lastname": '',
  #   "display_today_now_button": '1',
  #   "has_repeating_instruments_or_events": 0
  # }
  class ProjectAdmin < Admin::AdminBase
    include AdminHandler
    include NfsStore::ForAdminResources
    include OptionsHandler

    self.table_name = 'redcap_project_admins'

    has_one :redcap_data_dictionary,
            class_name: 'Redcap::DataDictionary',
            foreign_key: :redcap_project_admin_id,
            inverse_of: :redcap_project_admin

    has_many :redcap_client_requests,
             class_name: 'Redcap::ClientRequest',
             foreign_key: :redcap_project_admin_id,
             inverse_of: :redcap_project_admin

    validates :study, presence: true, unless: -> { disabled? }
    validates :name, presence: true, unless: -> { disabled? }
    validates :server_url, presence: true, unless: -> { disabled? }

    validate :name, -> { already_taken(:name, :study) ? errors.add(:name, 'already exists in this study') : true }

    before_save :empty_disabled_api_key

    after_save :create_file_store, unless: :file_store
    # After save, capture the project info from REDCap
    # except if the record has not saved or the current_project_info has
    # just changed, to avoid never ending callbacks
    after_save :capture_current_project_info, if: lambda {
                                                    force_refresh ||
                                                      (
                                                        !captured_project_info_changed? &&
                                                        saved_changes? &&
                                                        api_key.present?
                                                      )
                                                  }

    after_save :capture_data_dictionary, if: lambda {
                                               api_key.present? &&
                                                 captured_project_info.present? &&
                                                 (
                                                   saved_changes? ||
                                                   !data_dictionary_ready? ||
                                                   force_refresh
                                                 )
                                             }
    after_save :setup_dynamic_model,
               if: lambda {
                     ready_to_setup_dynamic_model? &&
                       (!dynamic_model_ready? || (saved_change_to_dynamic_model_table? && !dynamic_model_ready?) || force_refresh)
                   }

    after_save :reset_force_refresh

    attr_accessor :force_refresh, :use_hash_config

    #
    # Override Redcap records request with additional options, by default
    # to retrieve survey fields.
    configure :records_request_options, with: %i[exportSurveyFields
                                                 returnMetadataOnly
                                                 exportDataAccessGroups
                                                 returnFormat]

    configure :metadata_request_options, with: %i[returnFormat]

    #
    # Initialize with default request options for records and metadata
    def initialize(attrs = nil)
      attrs ||= {}
      attrs[:use_hash_config] ||= {}
      attrs[:use_hash_config][:records_request_options] ||= Settings::RedcapRecordsRequestOptions
      attrs[:use_hash_config][:metadata_request_options] ||= Settings::RedcapMetadataRequestOptions
      super
    end

    def config_text
      options
    end

    def config_text=(value)
      self.options = value
    end

    # Override the api_key accessor to return a decrypted value
    def api_key
      return unless attributes['api_key']

      ::Utilities::Encryption.decrypt(attributes['api_key'])
    end

    # Override the api_key= accessor to store an encrypted value to the database
    def api_key=(value)
      super(::Utilities::Encryption.encrypt(value))
    end

    #
    # Instantiate a project api_client for this project
    # Generally this should really be called within a Job rather than directly,
    # to avoid locking up the front end
    # @return [Redcap::ApiClient]
    def api_client
      @api_client ||= Redcap::ApiClient.new(self)
    end

    #
    # Override accessor for the attribute, to symbolize keys before return
    # @return [Hash | nil]
    def captured_project_info
      super&.symbolize_keys!
    end

    #
    # Dynamic storage instance for this project, allowing access to
    # dynamic model related functionality
    # @return [Redcap::DynamicStorage]
    def dynamic_storage
      return if dynamic_model_table.blank? || !persisted?

      @dynamic_storage ||= Redcap::DynamicStorage.new self, dynamic_model_table
    end

    #
    # In the background, download the full XML project archive,
    # and store it to the file_store container.
    def dump_archive
      Redcap::CaptureProjectArchiveJob.perform_later(self, current_admin)
    end

    #
    # Check if the dynamic model for storage is ready to use,
    # both the DB table has been created and the class is defined
    # @return [true | nil]
    def dynamic_model_ready?
      dynamic_storage&.dynamic_model_ready?
    end

    def data_dictionary_ready?
      redcap_data_dictionary&.all_retrievable_fields&.present?
    end

    #
    # Compare the field lists for that required by storage against
    # the actual dynamic model configuration
    # @return [Array{storage fields, dynamic model fields}]
    def compare_storage_and_model_field_lists
      fl = dynamic_storage.field_list
      dmfl = dynamic_storage.dynamic_model.field_list
      [fl, dmfl]
    end

    private

    #
    # Called before save to empty the api_key if the record is disabled
    def empty_disabled_api_key
      return unless disabled?

      self.api_key = nil
    end

    #
    # Called after save to store the captured project info from Redcap for future reference
    def capture_current_project_info
      Redcap::CaptureCurrentProjectInfoJob.perform_later(self)
    end

    #
    # Capture the data dictionary metadata from REDCap and store to table
    def capture_data_dictionary
      dd = redcap_data_dictionary || create_redcap_data_dictionary(current_admin: current_admin)

      dd.capture_data_dictionary
    end

    def reset_force_refresh
      self.force_refresh = nil
    end

    def ready_to_setup_dynamic_model?
      persisted? &&
        api_key.present? &&
        dynamic_model_table.present? &&
        captured_project_info.present? &&
        data_dictionary_ready?
    end

    #
    # Called after save to set up a dynamic model for this project
    # The #dynamic_model_table name will be used, which may optionally be
    # qualified with a schema name, as <schema name>.<table name>
    def setup_dynamic_model
      raise FphsException, 'Not ready to set up dynamic model / database table' unless ready_to_setup_dynamic_model?

      dynamic_storage.create_dynamic_model
      dynamic_storage.add_user_access_control
    end
  end
end
