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

    self.table_name = 'redcap_project_admins'

    has_one :redcap_data_dictionary, class_name: 'Redcap::DataDictionary', foreign_key: :redcap_project_admin_id
    has_many :redcap_client_requests, class_name: 'Redcap::ClientRequest', foreign_key: :redcap_project_admin_id

    validates :study, presence: true, unless: -> { disabled? }
    validates :name, presence: true, unless: -> { disabled? }
    validates :api_key, presence: true, unless: -> { disabled? }
    validates :server_url, presence: true, unless: -> { disabled? }

    validate :name, -> { already_taken(:name, :study) ? errors.add(:name, 'already exists in this study') : true }

    before_save :empty_disabled_api_key
    # After save, capture the project info from REDCap
    # except if the record has not saved or the current_project_info has
    # just changed, to avoid never ending callbacks
    after_save :capture_current_project_info, unless: -> { captured_project_info_changed? || !saved_changes? }
    after_save :capture_data_dictionary, if: -> { saved_changes? || force_refresh }
    after_save :setup_dynamic_model, if: -> { saved_change_to_id? || saved_change_to_dynamic_model_table? || force_refresh }
    after_save :reset_force_refresh

    attr_accessor :force_refresh

    # Override the api_key accessor to return a decrypted value
    def api_key
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
      return if dynamic_model_table.blank?

      @dynamic_storage ||= Redcap::DynamicStorage.new self, dynamic_model_table
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

    #
    # Called after save to set up a dynamic model for this project
    # The #dynamic_model_table name will be used, which may optionally be
    # qualified with a schema name, as <schema name>.<table name>
    def setup_dynamic_model
      return if dynamic_model_table.blank?

      dynamic_storage.create_dynamic_model
    end
  end
end
