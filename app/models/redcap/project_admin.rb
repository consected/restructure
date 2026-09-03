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
    self.table_name = 'redcap_project_admins'
    include AdminHandler
    include NfsStore::ForAdminResources
    include OptionsHandler

    Statuses = {
      schedule_run_set_configured: 'scheduled run configured',
      scheduled_run_successful: 'scheduled run successful',
      scheduled_run_completed_with_errors: 'scheduled run completed with errors',
      scheduled_run_failed: 'scheduled run failed',
      manual_run_successful: 'manual run successful',
      manual_run_completed_with_errors: 'manual run completed with errors',
      manual_run_failed: 'manual run failed',
      stopped_manually: 'stopped manually',
      changes_detected: 'changes detected',
      request_failed: 'request failed',
      invalid_metadata: 'invalid metadata'
    }.freeze

    JobQueue = 'redcap'
    RedcapSurveyIdentifierField = 'redcap_survey_identifier'
    ValidHandleDeletedRecordsValues = [nil, false, 'disable', 'ignore'].freeze

    has_one :redcap_data_dictionary,
            class_name: 'Redcap::DataDictionary',
            foreign_key: :redcap_project_admin_id,
            inverse_of: :redcap_project_admin

    has_many :redcap_project_users,
             class_name: 'Redcap::ProjectUser',
             foreign_key: :redcap_project_admin_id,
             inverse_of: :redcap_project_admin

    has_many :redcap_data_collection_instruments,
             class_name: 'Redcap::DataCollectionInstrument',
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

    before_save :clear_frequency_if_none

    before_save :set_schedule_status, if: lambda {
                                            frequency_changed? ||
                                              transfer_mode_changed? ||
                                              disabled_changed?
                                          }

    after_save :create_file_store, unless: :file_store

    after_save :reset_field_metadata, if: lambda {
                                            return false if disabled

                                            saved_change_to_captured_project_info? &&
                                              captured_project_info.nil?
                                          }

    # After save, capture the project info from REDCap
    # except if the record has not saved or the current_project_info has
    # just changed, to avoid never ending callbacks
    after_save :capture_current_project_info, if: lambda {
                                                    return false if disabled

                                                    force_refresh || request_latest_config ||
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
                                                   force_refresh ||
                                                   request_latest_config
                                                 )
                                             }

    after_save :capture_project_users, if: lambda {
                                             return false if disabled

                                             api_key.present? &&
                                               (
                                                 saved_change_to_server_url? ||
                                                 saved_change_to_api_key? ||
                                                 saved_change_to_name? ||
                                                 force_refresh ||
                                                 request_latest_config
                                               )
                                           }

    after_save :request_data_collection_instruments, if: lambda {
                                                           return false if disabled

                                                           api_key.present? &&
                                                             (
                                                               saved_change_to_server_url? ||
                                                               saved_change_to_api_key? ||
                                                               saved_change_to_name? ||
                                                               force_refresh ||
                                                               request_latest_config
                                                             )
                                                         }

    after_save :setup_dynamic_model, if: lambda {
                                           return false if disabled

                                           ready_to_setup_dynamic_model? &&
                                             valid_metadata? &&
                                             (
                                               !dynamic_model_ready? ||
                                               (saved_change_to_dynamic_model_table? && !dynamic_model_ready?) ||
                                               data_dictionary_changed? ||
                                               force_refresh
                                             )
                                         }

    after_save :setup_schedule, if: lambda {
                                      saved_change_to_frequency? ||
                                        saved_change_to_transfer_mode? ||
                                        saved_change_to_disabled? ||
                                        force_refresh
                                    }

    after_save :reset_refresh_flags

    attr_accessor :force_refresh, :request_latest_config, :use_hash_config, :in_background_job

    #
    # Override Redcap records request with additional options, by default
    # to retrieve survey fields.
    configure :records_request_options, with: %i[exportSurveyFields
                                                 returnMetadataOnly
                                                 exportDataAccessGroups
                                                 returnFormat]

    #
    # Return format for redcap metadata requests - typically not changed
    configure :metadata_request_options, with: %i[returnFormat]

    #
    # Specify options for the project.
    # add_multi_choice_summary_fields: automatically capture summary fields from checkbox fields with multiple responses
    #                                  providing a single array result field that can more easily be used within SQL
    #                                  without having to know each of the individual checkbox field columns in
    #                                  the database.
    # handle_deleted_records: specify how to handle records deleted on Redcap that have already been transferred
    #                         to the database. By default, the request fails. The options are:
    #                         - false/null: (default) to prevent a request with deleted records
    #                         - disable: set the disabled attribute for deleted records
    #                         - ignore: skip any deleted records
    #                         NOTE: with the *disabled* option, if a record subsequently "reappears" in Redcap
    #                         then the existing DB record will be set to disabled = false and updated appropriately
    # prefix_dynamic_model_config_library: category name
    #                      The "<category> <name>" string identifier for a
    #                      config library to be prefixed to the dynamic
    #                      model definition whenever it is updated.
    #                      For example: "redcap test_library"
    # associate_master_through_external_identifer: <external identifier> (optional: foreign key name)
    #                      Specify an external identifier resource name to use to look up the master record each
    #                      stored record is associated with. By default, "redcap_survey_identifier_id" is used as the
    #                      foreign key field used to look up the the external id. Optionally specify an alternative field name.
    # set_master_id_using_association: true|false
    #     If option `associate_master_through_external_identifer` is set, the ability to retrieve the master record
    #     can be used to set a `master_id` field directly on the dynamic model. Setting this option to *true* will
    #     add a `master_id` field automatically, and ensure it is set when records are retrieved from REDCap.
    #     NOTE: for large datasets that change regularly, this may slow down record retrieval significantly.
    # skip_store_if_no_survey_identifier: <Integer id> | nil
    #                      If we are using an association to match a redcap survey identifier to a master record
    #                      it won't be found if the public survey link was used and no survey identifier was populated.
    #                      This option allows the record to be skipped when pulling, allowing other records to be retrieved
    # run_jobs_as_user: <username>
    #     Sets the admin and matching user that will be used to run background jobs,
    #     such as getting project metadata or retrieving records from REDCap.
    #     New projects set this to the email address or id in settings `RedcapJobUserEmail`, which may be set by
    #     the environment variable `FPHS_RC_JOB_USER_EMAIL` or will default to the setting `BatchUserEmail`.
    #     If left blank in earlier projects or explicitly set to blank, the user matching the project's current admin will be used.
    # run_jobs_in_app_type: <app type name or id>
    #     Sets the app type that will be set on the `run_as_jobs_user`, effectively setting the
    #     access controls that authorize actions performed in background jobs such as retrieving records.
    #     This avoids an arbitrary app type being set, especially where the dynamic model being stored to has save triggers
    #     specified that may depend on access to specific resources.
    # metadata_export_cache_time: <Integer seconds>
    #     Time in seconds to cache metadata requests. Default is 60 seconds. Set to 0 to disable caching.
    # record_export_cache_time: <Integer seconds>
    #     Time in seconds to cache record requests. Default is 60 seconds. Set to 0 to disable caching.
    # internal_project_token: <String>
    #     A secret, per-project token required (in addition to a valid user_email/user_token) to authorize
    #     requests to the REDCap Data Entry Trigger endpoint (Redcap::ProjectUserRequestsController#data_entry_trigger).
    #     Automatically generated the first time the project is saved if not already set. Never regenerated
    #     automatically thereafter, since it is embedded in the Data Entry Trigger URL configured in REDCap.
    # export_only_updated_records: always | manual | nil
    #     If set, override the setting `dateRangeBegin` passed to the REDCap API and set it with the
    #     max(created_at, updated_at) for the table. This exports only records updated since the last retrieval.
    #     - 'always': always export using this rule (both scheduled and manual pulls)
    #     - 'manual': only manual pulls will export the updated records subset
    #     - 'scheduled': only scheduled pulls will export the updated records subset
    #     - nil/blank: disabled (exports all records)
    #     NOTE: returned subsets must be handled correctly by deleted record handling to avoid incorrectly
    #     marking excluded records as deleted.
    # continue_on_record_error: true | false | nil
    #     If true, an exception raised while persisting or triggering a single record during `store`
    #     (for example a before_save or after_commit save trigger) is caught and recorded in `errors` as
    #     `{ id:, errors:, action: :create_or_update }`, allowing the pull to continue processing the
    #     remaining records instead of aborting the entire run.
    #     - A failure during the before_save phase means the record's transaction was rolled back and the
    #       record was NOT persisted; it is not counted in #created_ids/#updated_ids.
    #     - A failure during the after_commit phase (e.g. create_reference, add_tracker, generate_document)
    #       means the record WAS already committed; it IS counted in #created_ids/#updated_ids, even though
    #       the failing trigger's own action did not complete.
    #     Default (false/nil): an unhandled exception aborts the entire pull (fail-fast, current behavior).

    ValidExportOnlyUpdatedRecordsValues = [nil, '', 'always', 'manual', 'scheduled'].freeze
    ValidContinueOnRecordErrorValues = [nil, '', true, false].freeze

    configure :data_options, with: %i[add_multi_choice_summary_fields
                                      handle_deleted_records
                                      prefix_dynamic_model_config_library
                                      associate_master_through_external_identifer
                                      set_master_id_using_association
                                      run_jobs_as_user
                                      run_jobs_in_app_type
                                      skip_store_if_no_survey_identifier
                                      metadata_export_cache_time
                                      record_export_cache_time
                                      export_only_updated_records
                                      server_time_zone
                                      continue_on_record_error
                                      internal_project_token]

    validate :data_options, lambda {
      return if data_options.handle_deleted_records.in?(ValidHandleDeletedRecordsValues)

      errors.add(:data_options, "handle_deleted_records must be one of: #{ValidHandleDeletedRecordsValues}")
    }

    validate :data_options, lambda {
      return if data_options.export_only_updated_records.in?(ValidExportOnlyUpdatedRecordsValues)

      errors.add(:data_options, "export_only_updated_records must be one of: #{ValidExportOnlyUpdatedRecordsValues}")
    }

    validate :data_options, lambda {
      tz = data_options.server_time_zone
      return if tz.blank?
      return if ActiveSupport::TimeZone[tz].present?

      errors.add(:data_options, "server_time_zone '#{tz}' is not a valid time zone identifier")
    }

    validate :data_options, lambda {
      return if data_options.continue_on_record_error.in?(ValidContinueOnRecordErrorValues)

      errors.add(:data_options, "continue_on_record_error must be one of: #{ValidContinueOnRecordErrorValues}")
    }
    #
    # A hash digest of the data dictionary, allowing any changes to indicate that an update is required
    configure_attributes :data_dictionary_version

    #
    # This project's secret internal_project_token, used to authorize requests to the REDCap
    # Data Entry Trigger endpoint. Generated and persisted (via #save_options/#update_columns,
    # bypassing validations/callbacks, matching #set_data_dictionary_version's pattern) the first
    # time it is accessed, if not already set; never regenerated once set.
    # NOTE: deliberately NOT a before_validation/before_save callback - OptionsHandler tracks
    # whether #config_text has changed since the record was loaded by comparing it against a
    # snapshot taken once at initialization (#orig_config_text). Since a new record's initial
    # snapshot is taken before any before_validation callback runs, generating this value in a
    # callback would permanently desynchronize that snapshot from the persisted value, causing
    # #update_options to discard unrelated, not-yet-saved data_options changes on every
    # subsequent save for the lifetime of the object.
    # @return [String]
    def internal_project_token
      token = data_options.internal_project_token
      return token if token.present?

      token = SecureRandom.hex(20)
      data_options.internal_project_token = token
      if persisted?
        save_options
        update_columns(options:)
        # Keep OptionsHandler's staleness snapshot in sync with the value we just wrote directly,
        # so a later #save! on this same instance doesn't see config_text as "changed elsewhere"
        # and reload (discarding) any other unsaved data_options changes.
        self.orig_config_text = config_text
      end
      token
    end

    #
    # Securely compare a token supplied by a caller (e.g. the REDCap Data Entry Trigger request)
    # against this project's internal_project_token, to protect against timing attacks.
    # Read-only: does not generate a token if one has not already been set.
    # @param [String] token
    # @return [Boolean]
    def matches_internal_project_token?(token)
      expected = data_options.internal_project_token
      return false if expected.blank? || token.blank?

      ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(expected.to_s),
        ::Digest::SHA256.hexdigest(token.to_s)
      )
    end

    #
    # Initialize with default request options for records and metadata
    def initialize(attrs = nil)
      attrs ||= {}
      attrs[:use_hash_config] ||= {}
      attrs[:use_hash_config][:records_request_options] ||= Settings::RedcapRecordsRequestOptions
      attrs[:use_hash_config][:metadata_request_options] ||= Settings::RedcapMetadataRequestOptions
      attrs[:use_hash_config][:data_options] ||= Settings::RedcapDataOptions

      super
    end

    #
    # Overrides method in NfsStore::ForAdminResources, ensuring the specified
    # job user is used if the file store has been created, or the current admin user if it
    # is in the process of being created
    def file_store_user
      if in_background_job
        job_user
      else
        current_admin&.matching_user
      end
    end

    #
    # Required to allow the filestore for this project to operate correctly.
    def secondary_key
      name
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
    # Override accessor for the attribute, to symbolize keys before return.
    # Uses the non-mutating #symbolize_keys (not #symbolize_keys!): mutating the JSONB attribute's
    # Hash in place makes ActiveRecord's dirty tracking see it as "changed" on every read, even
    # though nothing semantically changed.
    # @return [Hash | nil]
    def captured_project_info
      super&.symbolize_keys
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
    # In the background, download the XML project archive,
    # and store it to the file_store container.
    def dump_archive(definition_only: false)
      jobclass = Redcap::CaptureProjectArchiveJob
      jobs = archive_jobs(jobclass, definition_only:)
      return if jobs.count > 0

      jobclass.perform_later(self, definition_only:)
      record_job_request(archive_job_action(definition_only), result: { requested: true, definition_only: })
    end

    #
    # In the background, list the project users
    def capture_project_users
      pu = ProjectUsers.new self
      pu.request_users
    end

    #
    # In the background, remove a user's access from this REDCap project via
    # the REDCap API, then refresh the locally stored project user list.
    # @param [String] username - the REDCap username to remove
    def remove_project_user(username)
      pu = ProjectUsers.new self
      pu.request_remove_user(username)
    end

    #
    # Store the data dictionary metadata from Redcap for future reference
    # Calls a delayed job to actually do the work
    def request_data_collection_instruments
      Redcap::DataCollectionInstrument.capture_data_collection_instruments(self)
    end

    #
    # Request the event log from Redcap
    # Calls a delayed job to actually do the work
    def request_logs
      Redcap::ExportLogs.export_logs(self)
    end

    #
    # Store the arms and events metadata from Redcap for future reference
    # Calls a delayed job to actually do the work
    def request_arms_and_events
      # Redcap::Arm.capture_arms(self)
      # Redcap::Event.capture_events(self)
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
    # The name of the field representing a survey identifier.
    # Although this is most common, there may be future reasons to change it.
    def survey_identifier_field
      RedcapSurveyIdentifierField
    end

    #
    # The name of the field representing an integer version of the survey identifier.
    # Although this is most common, there may be future reasons to change it.
    def integer_survey_identifier_field
      "#{RedcapSurveyIdentifierField}_id"
    end

    #
    # Compare the field lists for that required by storage against
    # the actual dynamic model configuration.
    # Extra fields are those dependent on data_options, and will also appear in the storage fields list
    # if present
    # @return [Array{storage fields, dynamic model fields, extra fields}]
    def compare_storage_and_model_field_lists
      fl = dynamic_storage.field_list.split(' ')
      extras = dynamic_storage.extra_fields
      dmfl = dynamic_storage.dynamic_model.field_list.split(' ')
      [fl, dmfl, extras]
    end

    #
    # Do the field lists for that are required by storage match
    # the actual dynamic model configuration.
    # Additional fields in the dynamic model are acceptable
    # @return [Boolean]
    def model_has_all_fields_for_storage?
      storage_fields_a, dm_fields_a, extra_fields_a = compare_storage_and_model_field_lists
      (storage_fields_a + extra_fields_a - dm_fields_a).empty?
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
      return unless persisted?

      update_columns(status: Statuses[key], updated_at: DateTime.now)
    end

    #
    # The full REDCap Data Entry Trigger URL for this project, to be entered in REDCap's
    # Project Setup > Additional customizations > Data Entry Trigger "URL of website" field.
    # The `<user API token>` portion must be substituted by an admin with the real API token
    # of the user configured to submit these requests (see #data_entry_trigger_setup_info).
    # @return [String]
    def data_entry_trigger_url
      "#{Settings::BaseUrl}/redcap/project_user_requests/data_entry_trigger.json" \
        "?user_email=#{CGI.escape(Settings::RedcapDetUserEmail)}&user_token=<user API token>" \
        "&internal_project_token=#{internal_project_token}"
    end

    #
    # Lookup existing jobs, based on the jobclass being run, and the global id record
    # referenced in the arguments. Returns a scoped query, typically checked with something
    # like result.count > 0
    # @param [Class | String] job_class
    # @param [Admin::AdminBase] ref_record
    # @return [ActiveRecord::Relation]
    def self.existing_jobs(job_class, ref_record)
      Delayed::Job.lookup_jobs_by job_class:,
                                  ref_record:,
                                  queue: ProjectAdmin::JobQueue,
                                  failed: false
    end

    def archive_jobs(jobclass, definition_only:)
      jobs = self.class.existing_jobs(jobclass, self)
      pattern = '%definition_only: true%'
      definition_only ? jobs.where('handler LIKE ?', pattern) : jobs.where.not('handler LIKE ?', pattern)
    end

    def archive_job_action(definition_only)
      definition_only ? 'setup job: project definition' : 'setup job: project_xml'
    end

    #
    # When multiple active project admins match the same dynamic_model_table
    # we want to pick the one that actually captures data. Prefer a project admin
    # whose frequency is not 'never' and is the most recently created (highest id).
    # Fall back to the most recently created match if all candidates have frequency 'never'.
    # @param table_names [String, Array<String>] table name(s) to match
    # @return [Redcap::ProjectAdmin, nil]
    def self.preferred_active(table_names)
      ordered = active.where(dynamic_model_table: table_names).order(id: :desc)
      ordered.where.not(frequency: 'never').first || ordered.first
    end

    #
    # Find an active project admin matching a REDCap project_id, tolerating differences in the
    # supplied server_url. Used to identify the project associated with REDCap API callers that only
    # know their own project_id and REDCap base URL, such as project_id-based job requests and the
    # Data Entry Trigger endpoint.
    # Matching is attempted, in order:
    #  - exact server_url match
    #  - protocol + host match only (tolerating path differences, e.g. a caller sending
    #    https://redcap.partners.org/redcap/ when the project stores .../redcap/api/)
    # @param [String | Integer] project_id - REDCap project_id (captured_project_info['project_id'])
    # @param [String] server_url - the caller's REDCap base URL
    # @return [Redcap::ProjectAdmin, nil]
    def self.find_active_by_redcap_project(project_id, server_url)
      by_project_id = active
                      .where("captured_project_info ->> 'project_id' = ?", project_id.to_s)
                      .reorder('')
                      .order(updated_at: :desc)

      found = by_project_id.where(server_url:).first
      return found if found
      return if server_url.blank?

      uri = URI.parse(server_url)
      return unless uri.scheme.present? && uri.host.present?

      request_scheme = uri.scheme.downcase
      request_host = uri.host.downcase

      by_project_id.find do |project_admin|
        stored_uri = URI.parse(project_admin.server_url.to_s)
        stored_uri.scheme.present? &&
          stored_uri.host.present? &&
          stored_uri.scheme.downcase == request_scheme &&
          stored_uri.host.downcase == request_host
      rescue URI::InvalidURIError
        false
      end
    rescue URI::InvalidURIError
      nil
    end

    #
    # Find an active project admin by its internal_project_token alone. Used by the Data Entry
    # Trigger endpoint's GET "test" flow, which REDCap calls with only the params embedded in the
    # configured URL (no project_id/redcap_url).
    # @param [String] token
    # @return [Redcap::ProjectAdmin, nil]
    def self.find_active_by_internal_project_token(token)
      return if token.blank?

      active.find { |project_admin| project_admin.matches_internal_project_token?(token) }
    end

    #
    # Create a job request record for the *action*
    # If no result is specified, default to { requested: true }
    # @param [String] action
    # @param [Hash | nil] result - the information to store for the action
    # @return [Redcap::ClientRequest] the created job request instance
    def record_job_request(action, result: nil)
      result ||= { requested: true }

      curr_job_requests[action] =
        Redcap::ClientRequest.create(current_admin: current_admin || admin,
                                     action:,
                                     server_url:,
                                     name:,
                                     redcap_project_admin: self,
                                     result:)
    end

    #
    # Update the job request record for the *action*
    # If no result is specified, default to { requested: true }
    # @param [String] action
    # @param [Hash | nil] result - the information to store for the action
    def update_job_request(action, result: nil)
      result ||= { requested: true }

      res = curr_job_request_for(action)
      return unless res

      res.update current_admin: current_admin || admin,
                 result:
    end

    #
    # Does the project have repeating instruments or events, based on the
    # project metadata returned?
    # @return [true | false]
    def repeating_instruments?
      captured_project_info &&
        captured_project_info[:has_repeating_instruments_or_events] == 1
    end

    #
    # Does the project have longitudinal defined events, based on the
    # project metadata returned?
    # @return [true|false]
    def is_longitudinal?
      captured_project_info &&
        captured_project_info[:is_longitudinal] == 1
    end

    #
    # Returns the full model name, namespaced like 'module__class'
    def item_type
      name.singularize.ns_underscore
    end

    #
    # Force update of the dynamic model definition if it has already been created, typically to add new fields
    def update_dynamic_model
      raise FphsException, 'Not ready to update dynamic model / database table' unless ready_to_setup_dynamic_model?

      dynamic_storage.create_dynamic_model
      record_job_request 'update_dynamic_model', result: { dynamic_model: dynamic_storage.dynamic_model.id }
      # dynamic_storage.add_user_access_control
    end

    def disable_deleted_records?
      data_options.handle_deleted_records == 'disable'
    end

    def ignore_deleted_records?
      data_options.handle_deleted_records == 'ignore'
    end

    def fail_on_deleted_records?
      !data_options.handle_deleted_records
    end

    #
    # Check if transfer mode is set to 'none'
    # @return [Boolean]
    def transfer_mode_none?
      transfer_mode == 'none'
    end

    #
    # Returns true if the data_options.prefix_dynamic_model_config_library setting is blank
    # or if the dynamic model has the specified library in its options
    # @return [true|false]
    def dynamic_model_config_library_valid?
      data_options.prefix_dynamic_model_config_library.blank? || dynamic_storage&.dynamic_model_config_library_added?
    end

    def associate_master_through_external_id_valid?
      data_options.associate_master_through_external_identifer.blank? || dynamic_storage.dynamic_model_master_external_id_added?
    end

    def set_master_id_using_association_valid?
      !data_options.set_master_id_using_association || data_options.associate_master_through_external_identifer.present?
    end

    #
    # Specifies the external identifier resource name from associate_master_through_external_identifer
    def associate_master_through_external_id_resource_name
      res = data_options.associate_master_through_external_identifer
      return unless res.present?

      res.split(' ')[0]
    end

    #
    # Specifies the foreign key name from associate_master_through_external_identifer
    def associate_master_through_external_id_fkey_name
      res = data_options.associate_master_through_external_identifer
      return unless res.present?

      res.split(' ')[1] || integer_survey_identifier_field
    end

    def job_user
      return @job_user if @job_user

      ju = data_options.run_jobs_as_user
      res = User.find_active_by_email_or_id(ju) unless ju.blank?
      res ||= job_admin&.matching_user
      raise FphsException, "No user or matching admin found for job user '#{ju}'" unless res

      res.app_type = job_app_type if job_app_type
      @job_user = res
    end

    def job_admin
      return @job_admin if @job_admin

      ju = data_options.run_jobs_as_user
      res = Admin.find_active_by_email_or_id(ju) unless ju.blank?

      @job_admin = res || current_admin || admin
    end

    def job_app_type
      return @job_app_type if @job_app_type

      ja = data_options.run_jobs_in_app_type
      res = if ja
              Admin::AppType.find_active_by_name_or_id(ja)
            else
              current_user.app_type
            end
      @job_app_type = res
    end

    #
    # Get the date range begin timestamp for retrieving only updated records.
    # This is the created_at timestamp from the last successful 'store records' ClientRequest.
    # Returns nil if the option is not enabled or no successful store operation exists.
    # @return [DateTime | nil]
    def date_range_begin_for_manual_pull
      export_option = data_options.export_only_updated_records
      return nil unless export_option.in?(%w[always manual])

      last_successful_store_records_at
    end

    #
    # Get the appropriate timestamp for retrieving updated records.
    # Returns the earlier of either:
    # - The earliest timestamp of records with failed file fields (so they will be retried)
    # - The timestamp of the last successful store operation
    # @return [DateTime | nil]
    def last_successful_store_records_at
      earliest_failed = earliest_failed_file_field_record_timestamp
      last_store = last_successful_store_records_request_at

      [earliest_failed, last_store].compact.min
    end

    #
    # Get the created_at timestamp from the last successful 'store records' ClientRequest.
    # A successful store is one where the result has an empty errors array.
    # @return [DateTime | nil]
    def last_successful_store_records_request_at
      redcap_client_requests
        .where(action: 'store records')
        .where("result->>'errors' = '[]'")
        .order(created_at: :desc)
        .limit(1)
        .pick(:created_at)
    end

    #
    # Get the earliest (created_at, updated_at) timestamp from records that have
    # file fields marked with the FailedFileFieldMarker.
    # This ensures that records with failed file captures will be retried on subsequent pulls.
    # @return [DateTime | nil]
    def earliest_failed_file_field_record_timestamp
      return nil unless dynamic_model_ready?

      file_field_names = redcap_data_dictionary&.all_fields_of_type(:file)&.keys
      return nil if file_field_names.blank?

      model_class = dynamic_storage.dynamic_model&.implementation_class
      return nil unless model_class

      # Build a query to find records where any file field has the failed marker
      marker = Redcap::DataRecords::FailedFileFieldMarker
      conditions = file_field_names.map { |fn| "#{fn} = ?" }.join(' OR ')
      values = file_field_names.map { marker }

      records_with_failed_files = model_class.where(conditions, *values)
      return nil if records_with_failed_files.none?

      # Get the earliest timestamp (minimum of created_at or updated_at) for any failed record
      records_with_failed_files.minimum(Arel.sql('LEAST(created_at, updated_at)'))
    end

    #
    # Check if the export_only_updated_records option applies to manual pulls
    # (either 'manual' or 'always')
    # @return [Boolean]
    def export_only_updated_records_for_manual?
      data_options.export_only_updated_records.in?(%w[always manual])
    end

    def invalidate_cache
      logger.debug "Not invalidating cache (#{self.class.name})"
    end

    #
    # Check if this project has a failed status
    # @return [Boolean]
    def failed?
      return false unless frequency.present?

      status.in?([
                   Statuses[:scheduled_run_failed],
                   Statuses[:manual_run_failed],
                   Statuses[:request_failed]
                 ])
    end

    #
    # Check if the most recent run completed but with some individual record errors
    # recorded (see Redcap::DataRecords#errors), rather than a fully successful or
    # failed run
    # @return [Boolean]
    def completed_with_errors?
      status.in?([
                   Statuses[:scheduled_run_completed_with_errors],
                   Statuses[:manual_run_completed_with_errors]
                 ])
    end

    #
    # The status key (see Statuses) to use after a run completes without raising,
    # based on whether any per-record errors were recorded.
    # @param [Boolean] errors_present
    # @param [true | false] is_manual_pull
    # @return [Symbol]
    def self.completed_status(errors_present:, is_manual_pull:)
      if is_manual_pull
        errors_present ? :manual_run_completed_with_errors : :manual_run_successful
      else
        errors_present ? :scheduled_run_completed_with_errors : :scheduled_run_successful
      end
    end

    #
    # Get the timestamp of the most recent failure
    # @return [DateTime | nil]
    def failed_at
      return nil unless failed?

      # Get the most recent client request that might indicate when the failure occurred
      latest_request = redcap_client_requests
                       .order(updated_at: :desc, id: :desc)
                       .first

      latest_request&.updated_at || updated_at
    end

    #
    # Get all projects that are scheduled and have failed
    # @return [ActiveRecord::Relation]
    def self.failed_scheduled_projects
      active
        .where.not(frequency: [nil, ''])
        .where(status: [
                 Statuses[:scheduled_run_failed],
                 Statuses[:manual_run_failed],
                 Statuses[:request_failed]
               ])
    end

    #
    # Check if there are any failed scheduled projects
    # @return [Boolean]
    def self.any_failed_scheduled_projects?
      failed_scheduled_projects.exists?
    end

    private

    #
    # Called before save to empty the api_key if the record is disabled
    def empty_disabled_api_key
      return unless disabled?

      self.api_key = nil
    end

    #
    # Called before save to clear frequency if transfer mode is 'none'
    def clear_frequency_if_none
      return unless transfer_mode == 'none'

      self.frequency = nil
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
      redcap_data_dictionary&.update!(captured_metadata: nil, field_count: nil, current_admin:)
    end

    #
    # Capture the data dictionary metadata from REDCap and store to table
    def capture_data_dictionary
      dd = redcap_data_dictionary || create_redcap_data_dictionary(current_admin:)

      res = dd.capture_data_dictionary
      dd.reload
      res
    end

    def reset_refresh_flags
      self.force_refresh = nil
      self.request_latest_config = nil
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

    #
    # Check if the data dictionary version has changed
    # @return [true | false]
    def data_dictionary_changed?
      return false if data_dictionary_version == redcap_data_dictionary.captured_metadata_digest

      set_data_dictionary_version
      true
    end

    #
    # Set the data dictionary version in the options without triggering any model callbacks
    def set_data_dictionary_version
      self.data_dictionary_version = redcap_data_dictionary.captured_metadata_digest
      save_options
      update_columns(options:)
    end

    #
    # Memo of current job request records, to allow them to be updated in the future
    # Is a Hash or Redcap::ClientRequest instances, keyed by the action for the item
    # @return [Hash]
    def curr_job_requests
      @curr_job_requests ||= {}
    end

    #
    # Get the latest job request record for the action. This come from the memos or
    # will be retrieved from the database
    # @param [String] action
    # @return [Redcap::ClientRequest | nil]
    def curr_job_request_for(action)
      curr_job_requests[action] ||=
        Redcap::ClientRequest
        .where(
          action:,
          server_url:,
          name:,
          redcap_project_admin_id: id
        )
        .order(
          id: :desc
        )
        .first
    end
  end
end
