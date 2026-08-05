# frozen_string_literal: true

module Redcap
  #
  # Handle retrieved user records
  class ProjectUsers
    attr_accessor :project_admin, :records, :errors, :created_usernames, :updated_usernames,
                  :unchanged_usernames, :disabled_usernames,
                  :current_admin, :upserted_records

    def initialize(project_admin)
      super()
      self.project_admin = project_admin
      self.updated_usernames = []
      self.disabled_usernames = []
      self.created_usernames = []
      self.unchanged_usernames = []
      self.errors = []
      self.current_admin = project_admin.admin
      self.project_admin.current_admin = current_admin
      self.upserted_records = []
    end

    #
    # Request a background job retrieve user records and save them
    # @see Redcap::CaptureProjectUsersJob#perform_later
    # @param [Redcap::ProjectAdmin] project_admin
    def request_users
      jobclass = Redcap::CaptureProjectUsersJob
      jobs = Redcap::ProjectAdmin.existing_jobs(jobclass, project_admin)
      return if jobs.count > 0

      jobclass.perform_later(project_admin)
      project_admin.record_job_request('setup job: list project users')
    end

    #
    # Request a background job to remove a user's access from the project
    # via the REDCap API, then refresh the locally stored project user list.
    # @see Redcap::RemoveProjectUserJob#perform_later
    # @param [String] username - the REDCap username to remove
    def request_remove_user(username)
      jobclass = Redcap::RemoveProjectUserJob
      jobs = Redcap::ProjectAdmin.existing_jobs(jobclass, project_admin)
      return if jobs.count > 0

      jobclass.perform_later(project_admin, username)
      project_admin.record_job_request('remove project user', result: { requested: true, username: })
    end

    #
    # Immediately retrieve, validate and store the records from REDCap.
    # This is only intended to be called from a background job.
    # @param [Boolean] force_reload - bypass any cached #project_users response
    #   (see Redcap::ApiClient#remove_project_user, which does not itself
    #   invalidate the cache)
    def retrieve_validate_store(force_reload: false)
      retrieve(force_reload:)
      validate
      store
    end

    #
    # Immediately retrieve records from REDCap.
    # This is only intended to be called from a background job.
    # @param [Boolean] force_reload - bypass any cached #project_users response
    # @return [Array{Hash}]
    def retrieve(force_reload: false)
      self.records = project_admin.api_client.project_users(force_reload:)
    end

    #
    # Perform validations on the records returned
    # We choose to fail with an exception for these, since any of them
    # represent bad data retrieved from Redcap, which could indicate corruption
    # of the data, which should not make it to the local database
    def validate
      unless records.is_a? Array
        raise FphsException, "Redcap::ProjectUser did not return an array: #{records.class.name}"
      end

      return unless records.first

      return true if records.first.is_a? Hash

      raise FphsException, "Redcap::ProjectUser did not return a hash as first item: #{records.first.class.name}"
    end

    #
    # Store (upsert) each of the retrieved records into the named model.
    # This is done iteratively, to ensure that callbacks are fired.
    # Error will appear in #errors
    # IDs of created items will appear in #created_usernames
    # IDs of updated items will appear in #updated_usernames
    # IDs of disabled items will appear in #disabled_usernames
    def store
      upserts = []

      records.each do |record|
        res = create_or_update record
        upserts << res if res
      end

      unless errors.present?
        handled_updates = created_usernames + updated_usernames + unchanged_usernames

        all_disabled = project_admin.redcap_project_users.active
                                    .where.not(username: handled_updates)

        self.disabled_usernames = all_disabled.pluck(:username)
        all_disabled.update_all(disabled: true, admin_id: current_admin)
      end

      result = {
        created_usernames:,
        updated_usernames:,
        unchanged_usernames:,
        disabled_usernames:,
        errors:
      }

      project_admin.record_job_request('store project users', result:)
    end

    #
    # Handle creation of new record if the record does not already exist based on its
    # username matching, update if it does exist and has new information, or
    # do nothing if it exists and is unchanged.
    # Validations are applied to creates and updates and errors are returned within an
    # errors array.
    # If an update or create is successful, return the username, if there is no change return false
    # and if there is any other result (an error) return nil.
    # @param [Hash] record
    # @return [Integer | false | nil]
    def create_or_update(record)
      username = record[:username]
      existing_record = project_admin.redcap_project_users.active.where(username:).first

      if existing_record
        # Check if there is an exact match for the record. If so, we are done
        if record_matches_retrieved(existing_record, record)
          unchanged_usernames << username
          return false
        end

        existing_record.current_admin = current_admin
        if existing_record.update(record.slice(*all_expected_field_names))
          updated_usernames << username
          upserted_records << existing_record
          username
        else
          errors << { username:, errors: existing_record.errors, action: :update }
        end
      else
        new_record = ProjectUser.new(record.slice(*all_expected_field_names))
        new_record.redcap_project_admin_id = project_admin.id
        new_record.current_admin = current_admin
        if new_record.save
          created_usernames << username
          upserted_records << new_record
          return username
        else
          errors << { id: username, errors: new_record.errors, action: :create }
        end
      end

      nil
    end

    #
    # Check if a stored record matches the retrieved record.
    # @param [Redcap::ProjectUser] existing_record
    # @param [Hash{Symbol => String}] record
    # @return [true]
    def record_matches_retrieved(existing_record, record)
      check_rec = record.dup
      check_rec.slice!(*all_expected_field_names)
      attrs = existing_record.attributes.symbolize_keys.dup
      attrs.slice!(*all_expected_field_names)

      check_rec == attrs
    end

    private

    #
    # All fields expected to be retrieved from REDCap to be stored as a record
    # @return [Array]
    def all_expected_field_names
      @all_expected_field_names ||= %i[username email expiration]
    end
  end
end
