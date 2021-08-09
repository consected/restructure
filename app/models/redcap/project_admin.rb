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

    Statuses = {
      schedule_run_set_configured: 'scheduled run configured',
      scheduled_run_successful: 'scheduled run successful',
      scheduled_run_failed: 'scheduled run failed',
      manual_run_successful: 'manual run successful',
      manual_run_failed: 'manual run failed',
      stopped_manually: 'stopped manually',
      changes_detected: 'changes detected',
      request_failed: 'request failed',
      invalid_metadata: 'invalid metadata'
    }.freeze

    JobQueue = 'redcap'

    has_one :redcap_data_dictionary,
            class_name: 'Redcap::DataDictionary',
            foreign_key: :redcap_project_admin_id,
            inverse_of: :redcap_project_admin

    has_many :redcap_project_users,
             class_name: 'Redcap::ProjectUser',
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
    validate :frequency, lambda {
      disabled? ||
        frequency.blank? ||
        FieldDefaults.duration(frequency) ||
        errors.add(:frequency, 'has invalid value')
    }

    before_save :empty_disabled_api_key

    before_save :set_schedule_status, if: lambda {
                                            (
                                              frequency_changed? ||
                                              transfer_mode_changed? ||
                                              disabled_changed?
                                            )
                                          }

    after_save :create_file_store, unless: :file_store

    after_save :reset_field_metadata, if: lambda {
                                            return false if disabled

                                            (
                                              saved_change_to_captured_project_info? &&
                                              captured_project_info.nil?
                                            )
                                          }

    # After save, capture the project info from REDCap
    # except if the record has not saved or the current_project_info has
    # just changed, to avoid never ending callbacks
    after_save :capture_current_project_info, if: lambda {
                                                    return false if disabled

                                                    force_refresh ||
                                                      (
                                                        !saved_change_to_captured_project_info? &&
                                                        api_key.present? &&
                                                        (
                                                          saved_change_to_server_url? ||
                                                          saved_change_to_api_key? ||
                                                          saved_change_to_name?
                                                        )
                                                      )
                                                  }

    after_save :capture_data_dictionary, if: lambda {
                                               return false if disabled

                                               api_key.present? &&
                                                 captured_project_info.present? &&
                                                 valid_metadata? &&
                                                 (
                                                    saved_change_to_server_url? ||
                                                    saved_change_to_api_key? ||
                                                    saved_change_to_name? ||
                                                    !data_dictionary_ready? ||
                                                    force_refresh
                                                  )
                                             }

    after_save :capture_project_users, if: lambda {
                                             return false if disabled

                                             api_key.present? &&
                                               (
                                                 saved_change_to_server_url? ||
                                                 saved_change_to_api_key? ||
                                                 saved_change_to_name? ||
                                                 force_refresh
                                               )
                                           }

    after_save :setup_dynamic_model, if: lambda {
                                           return false if disabled

                                           ready_to_setup_dynamic_model? &&
                                             valid_metadata? &&
                                             (
                                               !dynamic_model_ready? ||
                                               (saved_change_to_dynamic_model_table? && !dynamic_model_ready?) ||
                                               force_refresh
                                             )
                                         }

    after_save :setup_schedule, if: lambda {
                                      (
                                        saved_change_to_frequency? ||
                                        saved_change_to_transfer_mode? ||
                                        saved_change_to_disabled? ||
                                        force_refresh
                                      )
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

      super(attrs)
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
      jobclass = Redcap::CaptureProjectArchiveJob
      jobs = self.class.existing_jobs(jobclass, self)
      return if jobs.count > 0

      jobclass.perform_later(self, current_admin)
      record_job_request('setup job: project_xml')
    end

    #
    # In the background, list the project users
    def capture_project_users
      pu = ProjectUsers.new self
      pu.request_users
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

    #
    # Do the field lists for that required by storage match
    # the actual dynamic model configuration
    # @return [Boolean]
    def storage_and_model_fields_match?
      pair = compare_storage_and_model_field_lists
      pair[0] == pair[1]
    end

    def valid_metadata?
      captured_project_info && captured_project_info[:project_title] == name
    end

    #
    # Get the Delayed::Job for this schedule
    # @return [Delayed::Job | nil]
    def task_schedule
      RecurringPullTask.task_schedule(self).first
    end

    #
    # Update status in record immediately
    # @param [Symbol] key - status key from Statuses
    def update_status(key)
      return if force_refresh # Failsafe to prevent infinite loops from callbacks
      return unless persisted?

      update(status: Statuses[key])
    end

    #
    # Lookup existing jobs, based on the jobclass being run, and the global id record
    # referenced in the arguments. Returns a scoped query, typically checked with something
    # like result.count > 0
    # @param [Class | String] jobclass
    # @param [Admin::AdminBase] ref_record
    # @return [ActiveRecord::Relation]
    def self.existing_jobs(jobclass, ref_record)
      jobtext = <<~END_TEXT
        %
          job_class: #{jobclass}
        %
          - _aj_globalid: gid://#{Settings::GlobalIdPrefix}/#{ref_record.class}/#{ref_record.id}
        %
      END_TEXT
      Delayed::Job.handler_includes jobtext, queue: ProjectAdmin::JobQueue, failed: false
    end

    def record_job_request(action, result: nil)
      result ||= { requested: true }
      Redcap::ClientRequest.create current_admin: current_admin || admin,
                                   action: action,
                                   server_url: server_url,
                                   name: name,
                                   redcap_project_admin: self,
                                   result: result
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
      jobclass = Redcap::CaptureCurrentProjectInfoJob
      jobs = self.class.existing_jobs(jobclass, self)
      return if jobs.count > 0

      jobclass.perform_later(self)
      record_job_request('setup job: project')
    end

    def reset_field_metadata
      redcap_data_dictionary&.update!(captured_metadata: nil, field_count: nil, current_admin: current_admin)
    end

    #
    # Capture the data dictionary metadata from REDCap and store to table
    def capture_data_dictionary
      dd = redcap_data_dictionary || create_redcap_data_dictionary(current_admin: current_admin)

      res = dd.capture_data_dictionary
      dd.reload
      res
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
      record_job_request 'create_dynamic_model', result: { dynamic_model: dynamic_storage.dynamic_model.id }
      dynamic_storage.add_user_access_control
    end

    #
    # Schedule or unschedule a recurring pull for this project admin instance
    def setup_schedule
      if disabled || frequency.blank? || transfer_mode != 'scheduled' || !persisted? || !dynamic_model_ready?
        RecurringPullTask.unschedule_task self
        self.status = Statuses[:stopped_manually]
      else
        RecurringPullTask.schedule_task self,
                                        { project_admin: to_global_id.to_s,
                                          class_name: dynamic_storage.dynamic_model_class_name },
                                        run_every: FieldDefaults.duration(frequency)

        self.status = Statuses[:schedule_run_set_configured]
      end
    end

    #
    # Schedule or unschedule a recurring pull for this project admin instance
    def set_schedule_status
      self.status = if disabled || frequency.blank? || transfer_mode != 'scheduled'
                      Statuses[:stopped_manually]
                    else
                      Statuses[:schedule_run_set_configured]
                    end
    end
  end
end
