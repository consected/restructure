# frozen_string_literal: true

module Redcap
  #
  # Representation of a Redcap project as configured by an administrator
  class ProjectAdmin < Admin::AdminBase
    include AdminHandler

    self.table_name = 'redcap_project_admins'

    has_one :redcap_data_dictionary, class_name: 'Redcap::DataDictionary', foreign_key: :redcap_project_admin_id
    has_many :redcap_client_requests, class_name: 'Redcap::ClientRequest'

    validates :name, presence: true, unless: -> { disabled? }
    validates :api_key, presence: true, unless: -> { disabled? }
    validates :server_url, presence: true, unless: -> { disabled? }

    validate :name, -> { already_taken(:name) ? errors.add(:name, 'already exists') : true }
    validate :api_key, -> { already_taken(:api_key) ? errors.add(:api_key, 'already exists') : true }
    validate :server_url, -> { already_taken(:server_url) ? errors.add(:server_url, 'already exists') : true }

    before_save :empty_disabled_api_key
    # After save, capture the project info from REDCap
    # except if the record has not saved or the current_project_info has
    # just changed, to avoid never ending callbacks
    after_save :capture_current_project_info, unless: -> { captured_project_info_changed? || !saved_changes? }
    after_save :capture_data_dictionary, if: -> { saved_changes? || force_refresh }
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
    # Instantiate a project client for this project
    # Generally this should really be called within a Job rather than directly,
    # to avoid locking up the front end
    # @return [Redcap::ProjectClient]
    def project_client
      @project_client ||= ProjectClient.new(self)
    end

    #
    # Override accessor for the attribute, to symbolize keys before return
    # @return [Hash | nil]
    def captured_project_info
      super&.symbolize_keys!
    end

    private

    #
    # Called before save to empty the api_key if the record is disabled
    def empty_disabled_api_key
      return unless disabled?

      self.api_key = nil
    end

    def project_info_cache_key
      "#{self.class.name.ns_underscore}--#{id}-#{created_at}-#{updated_at}"
    end

    #
    # Called after save to store the captured project info from Redcap for future reference
    def capture_current_project_info
      Redcap::CaptureCurrentProjectInfoJob.perform_later(self)
    end

    def capture_data_dictionary
      dd = redcap_data_dictionary || create_redcap_data_dictionary(current_admin: current_admin)

      dd.capture_data_dictionary
    end

    def reset_force_refresh
      self.force_refresh = nil
    end
  end
end
