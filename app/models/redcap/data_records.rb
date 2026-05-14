# frozen_string_literal: true

module Redcap
  #
  # Handle and validate retrieved records
  # Works with the dynamic models created by Redcap::DynamicStorage, although this is not strictly required
  class DataRecords
    # The job request record will be updated every *n* records to provide feedback to the admin
    UpdateJobRequestEvery = 20

    # Marker string used to identify file fields that failed to be captured.
    # This allows failed file fields to be searched for in the database,
    # and ensures records with failed file fields are retried on subsequent pulls.
    # The string is designed to be unlikely to be a valid filename.
    FailedFileFieldMarker = '<<FAILED-FILE-CAPTURE>>'

    attr_accessor :project_admin, :records, :class_name, :errors,
                  :created_ids, :updated_ids, :unchanged_ids, :disabled_ids, :storage_stage,
                  :current_admin, :retrieved_files, :upserted_records, :imported_files, :failed_files,
                  :step_count, :job, :done,
                  :integer_survey_identifier_field_name, :survey_identifier_field_name, :set_master_id_using_association,
                  :skip_store_if_no_survey_identifier, :skipped_ids,
                  :external_id_fkey_name,
                  :retrieved_from_cache, :using_date_range_filter, :is_manual_pull,
                  :date_range_begin,
                  :request_source,
                  :verify_file_fields

    def initialize(project_admin, class_name, is_manual_pull: false, request_source: nil, verify_file_fields: false)
      super()
      self.project_admin = project_admin
      self.class_name = class_name
      self.storage_stage = ''
      self.updated_ids = []
      self.created_ids = []
      self.unchanged_ids = []
      self.disabled_ids = []
      self.skipped_ids = []
      self.errors = []
      self.current_admin = project_admin.admin
      self.project_admin.current_admin = current_admin
      self.retrieved_files = {}
      self.upserted_records = []
      self.imported_files = []
      self.failed_files = []
      self.step_count = UpdateJobRequestEvery
      self.survey_identifier_field_name = project_admin.survey_identifier_field.to_sym
      self.integer_survey_identifier_field_name = project_admin.integer_survey_identifier_field.to_sym
      self.external_id_fkey_name = project_admin.associate_master_through_external_id_fkey_name&.to_sym
      self.set_master_id_using_association = project_admin.data_options.set_master_id_using_association
      self.skip_store_if_no_survey_identifier = project_admin.data_options.skip_store_if_no_survey_identifier
      self.retrieved_from_cache = false
      self.using_date_range_filter = false
      self.is_manual_pull = is_manual_pull
      self.request_source = request_source
      # Only honour file-field verification on manual (admin-initiated) pulls so
      # scheduled pulls remain fast. On scheduled pulls the option is forced off.
      self.verify_file_fields = is_manual_pull && verify_file_fields
    end

    #
    # Request a background job retrieve records and save them to the specified model
    # @see Redcap::CaptureRecordsJob#perform_later
    # @param [Boolean] ignore_cache - force pull from REDCap, bypassing cache
    # @param [Boolean] retrieve_all - ignore export_only_updated_records setting and retrieve all records
    # @param [Boolean] verify_file_fields - on manual pulls, treat records as changed when a file
    #                                       field's underlying stored file is missing.
    def request_records(ignore_cache: false, retrieve_all: false, verify_file_fields: false)
      jobclass = Redcap::CaptureRecordsJob
      jobs = ProjectAdmin.existing_jobs(jobclass, project_admin)
      return if jobs.count > 0

      self.job = Redcap::CaptureRecordsJob.perform_later(project_admin, class_name,
                                                         ignore_cache:,
                                                         retrieve_all:,
                                                         verify_file_fields:)
      return if Rails.application.config.active_job.queue_adapter == :inline

      source_result = request_source ? { request_source => true } : {}
      project_admin.record_job_request('setup job: store records',
                                       result: { requested: true, job: job&.job_id }.merge(source_result))
    end

    #
    # Immediately retrieve, validate and store the records from REDCap.
    # This is only intended to be called from a background job.
    # If records are retrieved from cache, skip validate and store steps
    # since they will have already been processed by the first retrieval.
    # If an exception occurs, record it in the job request before re-raising
    # to ensure the error is captured and this run is not considered successful.
    # @param [Boolean] ignore_cache - force pull from REDCap, bypassing cache
    # @param [Boolean] retrieve_all - ignore export_only_updated_records setting and retrieve all records
    def retrieve_validate_store(ignore_cache: false, retrieve_all: false)
      self.storage_stage = 'retrieve_validate_store'
      # Calculate date_range_begin BEFORE creating new job request record,
      # so we get the timestamp from the previous successful run
      self.date_range_begin = retrieve_all ? nil : calculate_date_range_begin
      self.using_date_range_filter = date_range_begin.present?
      update_job_request(create: true)
      retrieve(ignore_cache:, retrieve_all:)

      # If records came from cache, skip validation and storage
      # since they have already been processed
      if retrieved_from_cache
        self.storage_stage = 'skipped (from cache)'
        update_job_request
        return
      end

      summarize_fields
      handle_survey_identifier
      validate
      store
    rescue StandardError => e
      self.errors ||= []
      self.errors << { error: e.to_s, backtrace: e.short_string_backtrace }
      # Append failure indicator to preserve which stage failed
      self.storage_stage = "#{storage_stage} (failed)"
      update_job_request
      raise
    end

    #
    # Immediately retrieve records from REDCap.
    # This is only intended to be called from a background job.
    # Each record is a Hash, keyed by a symbol.
    # If export_only_updated_records option is enabled, adds dateRangeBegin
    # to retrieve only records updated since the last retrieval.
    # Note: date_range_begin is typically set by retrieve_validate_store before
    # creating the new job request record, but we support setting it here for
    # direct calls to retrieve.
    # @param [Boolean] ignore_cache - force pull from REDCap, bypassing cache
    # @param [Boolean] retrieve_all - ignore export_only_updated_records setting and retrieve all records
    # @return [Array{Hash}]
    def retrieve(ignore_cache: false, retrieve_all: false)
      # Only calculate if not already set (retrieve_validate_store sets it earlier)
      self.date_range_begin ||= retrieve_all ? nil : calculate_date_range_begin
      self.using_date_range_filter = date_range_begin.present?

      self.records = project_admin.api_client.records(date_range_begin:, ignore_cache:)
      self.retrieved_from_cache = project_admin.api_client.last_result_from_cache
      self.storage_stage = 'retrieve'
      update_job_request
      records
    end

    #
    # Summarize the multiple choice checkbox fields into _chosen_array fields
    # if the project requests it
    # The method runs through each of the columns, and for any fields requiring
    # summarization adds them to all the records in the current @records set.
    # At this point, prior to storage, the individual checkbox fields return a string
    # value "1" checked, or "0" unchecked. We check for "1" and add the
    # field value represented by that checkbox to the array. Subsequent tag_select UI field
    # processing can display these options appropriately, and SQL can make comparisons
    # against this single field without needing knowledge of additional options that may be
    # added in the future.
    def summarize_fields
      return unless project_admin.data_options.add_multi_choice_summary_fields

      self.storage_stage = 'summarize_fields'
      update_job_request

      all_rc_fields = data_dictionary.all_fields
      all_rc_fields.each_value do |field|
        next unless field.field_type.name == :checkbox

        next unless field.has_checkbox_summary_array?

        ccfs = field.checkbox_choice_fields
        next unless ccfs.present?

        cf_name = field.chosen_array_field_name
        records.each do |rec|
          vals = ccfs.map { |ccf| rec[ccf.to_sym] == '1' && field.choice_field_value(ccf) }
                     .select { |item| item }
          rec[cf_name] = vals
        end
      end
    end

    #
    # The redcap_survey_identifier string field will be returned if the project option exportSurveyFields is true.
    # Other options require it to be processed for storage in other forms.
    def handle_survey_identifier
      records_request_options = project_admin.records_request_options
      return unless records_request_options.exportSurveyFields

      am = project_admin.data_options.associate_master_through_external_identifer
      return unless am

      @has_integer_survey_identifier = true
      return unless external_id_fkey_name == integer_survey_identifier_field_name

      si_name = survey_identifier_field_name
      integer_si_name = integer_survey_identifier_field_name

      return unless records.first.has_key?(si_name)

      records.each do |rec|
        val = rec[si_name]
        val = nil if val.blank?
        rec[integer_si_name] = val&.to_i
      end
    end

    #
    # Immediately retrieve file from a REDCap file field for a
    # specific record. The most recent request is stored to the
    # retrieved_files Hash.
    # @return [Hash{Symbol => File}] <description>
    def retrieve_file(record_id, field_name, event: nil)
      retrieved_files[field_name] = project_admin.api_client.file record_id, field_name, event:
    end

    #
    # Perform validations on the records returned
    # We choose to fail with an exception for these, since any of them
    # represent bad data retrieved from Redcap, which could indicate corruption
    # of the data, which should not make it to the local database
    def validate
      self.storage_stage = 'validate'
      update_job_request

      unless records.is_a? Array
        raise FphsException, "Redcap::DataRecords did not return an array: #{records.class.name}"
      end

      return unless records.first

      unless records.first.is_a? Hash
        raise FphsException,
              "Redcap::DataRecords did not return a hash as first item: #{records.first.class.name}"
      end

      overlapping_fields = records.first.keys & model.attribute_names.map(&:to_sym)
      unless overlapping_fields.length == records.first.keys.length
        missing_fields = records.first.keys - model.attribute_names.map(&:to_sym)
        raise FphsException, "Redcap::DataRecords::ModelMissingFields retrieved record fields are not present in the model:\n" \
                             "#{missing_fields.join(' ')}"
      end

      # We have to ignore fields named <form>_timestamp when checking
      # for completeness of the retrieved records, since the API offers
      # no way of recognizing which forms have surveys available and would
      # therefore return a _timestamp field when completed.
      timestamp_fields = project_admin.redcap_data_dictionary.form_names.map { |f| :"#{f}_timestamp" }
      expected_minus_form_timestamps = all_data_dictionary_fields.keys - timestamp_fields
      records.each do |r|
        actual_fields_minus_timestamps = r.keys - timestamp_fields
        next if actual_fields_minus_timestamps.sort == expected_minus_form_timestamps.sort

        raise FphsException,
              "Redcap::DataRecords::MismatchFields retrieved record fields don't match the data dictionary:\n" \
              "missing: #{(expected_minus_form_timestamps - actual_fields_minus_timestamps).sort.join(' ')}\n" \
              "additional: #{(actual_fields_minus_timestamps - expected_minus_form_timestamps).sort.join(' ')}"
      end

      # Skip deleted records validation when using date range filter
      # since we're only retrieving a subset of updated records
      return if using_date_range_filter

      if project_admin.fail_on_deleted_records? && records.length < existing_records_length
        raise FphsException,
              "Redcap::DataRecords retrieved fewer records (#{records.length}) " \
              "than expected (#{existing_records_length})"
      end

      if retrieved_rec_ids.find { |r| r[record_id_field].blank? }
        raise FphsException, 'Redcap::DataRecords retrieved data that has a nil record id'
      end

      return if existing_not_in_retrieved_ids.empty? ||
                project_admin.ignore_deleted_records? || project_admin.disable_deleted_records?

      raise FphsException,
            'Redcap::DataRecords existing records were not in the retrieved records: ' \
            "#{existing_not_in_retrieved_ids.join(', ')}"
    end

    #
    # Store (upsert) each of the retrieved records into the named model.
    # This is done iteratively, to ensure that callbacks are fired.
    # Error will appear in #errors
    # IDs of created items will appear in #created_ids
    # IDs of updated items will appear in #updated_ids
    # For each updated or created record, also download the file fields to the
    # associated file store
    # The actual processing is paged, limiting the number of records processed
    # to the value set in #step_count. This is intended to limit the memory consumption
    # from holding record instances in #upserted_records
    def store
      # Skip deleted records handling when using date range filter
      # since we're only retrieving a subset of updated records
      disable_deleted_records if project_admin.disable_deleted_records? && !using_date_range_filter

      upserts = []
      self.storage_stage = 'store'
      update_job_request

      self.done = 0
      from = 0
      step = step_count

      ((records.length / step) + 1).times do
        subset = records[from, step]
        self.upserted_records = []
        subset.each do |record|
          res = create_or_update record
          upserts << res if res
        end

        upserted_records.each do |record|
          capture_files record
        end
        from += step
        self.done = from
        update_job_request
      end

      self.done = records.length
      self.storage_stage = 'store complete'
      update_job_request
    end

    #
    # Retrieve all model records
    # @return [ActiveRecord::Relation]
    def existing_records
      model.all
    end

    #
    # Count of existing records stored as the model
    # @return [Integer]
    def existing_records_length
      existing_records.count
    end

    #
    # Array of Redcap record ids, based on the record_id_field
    # These are full hashes of identifying attributes, to handle repeated records.
    # The values are cast to strings, to allow easier comparison later
    # @return [Array{Hash}]
    def retrieved_rec_ids
      return @retrieved_rec_ids if @retrieved_rec_ids

      @retrieved_rec_ids = records.map do |r|
        record_identifier_fields.map { |f| [f, r[f].to_s] }.to_h
      end
    end

    #
    # Array of database record ids that were not retrieved in the Redcap records.
    # These are full hashes of identifying attributes, to handle repeated records
    # @return [Array{Hash}]
    def existing_not_in_retrieved_ids
      return @existing_not_in_retrieved_ids if @existing_not_in_retrieved_ids

      existing_rec_ids = existing_records.select(record_identifier_fields).to_a
      existing_rec_ids = existing_rec_ids.map { |r| r.attributes.symbolize_keys.slice(*record_identifier_fields) }
      @existing_not_in_retrieved_ids = existing_rec_ids - retrieved_rec_ids
    end

    private

    def data_dictionary
      project_admin.redcap_data_dictionary
    end

    #
    # Calculate the dateRangeBegin value based on the created_at timestamp of the last
    # successful 'store records' ClientRequest for this project.
    # This is more accurate than using record timestamps since it captures when we
    # actually pulled from REDCap, not when records were stored locally.
    # Returns nil if export_only_updated_records is not enabled for this pull type.
    # @return [DateTime | nil]
    def calculate_date_range_begin
      export_option = project_admin.data_options.export_only_updated_records
      return nil if export_option.blank?

      # Check if this is a manual or scheduled pull and if the option applies
      # 'manual' applies only to manual pulls
      # 'scheduled' applies only to scheduled pulls
      # 'always' applies to both
      return nil if export_option == 'manual' && !is_manual_pull
      return nil if export_option == 'scheduled' && is_manual_pull

      # Get the created_at timestamp from the last successful 'store records' ClientRequest
      project_admin.last_successful_store_records_at
    end

    #
    # The sequential record_id field is not a fixed name. Get it from the data dictionary
    # @return [Symbol]
    def record_id_field
      data_dictionary.record_id_field
    end

    #
    # Extra fields used to uniquely identify a record (e.g. for repeat instruments)
    # @return [Array{Symbol} | nil]
    def record_id_extra_fields
      data_dictionary.record_id_extra_fields
    end

    #
    # Full list of fields used to identify a record
    # @return [Array]
    def record_identifier_fields
      getfields = [record_id_field]
      getfields += record_id_extra_fields if record_id_extra_fields
      getfields
    end

    #
    # All fields expected to be retrieved from REDCap to be stored as a record
    # @return [Hash{Symbol => Redcap::DataDictionaries::Field}]
    def all_data_dictionary_fields
      @all_data_dictionary_fields ||= data_dictionary.all_retrievable_fields(summary_fields: true)
    end

    #
    # The model we are using to instantiate records
    # @return [DynamicModel]
    def model
      @model ||= class_name.constantize
      return @model if @model < Dynamic::DynamicModelBase

      raise FphsException,
            "Redcap::DataRecords model is not a valid type: #{class_name}"
    end

    #
    # Hash of fields that identify the current record. For classic instruments,
    # this is simply a record id field. For repeating instruments, additional fields
    # are required to uniquely identify the record.
    # @param [Hash] record
    # @return [Hash]
    def record_identifiers(record)
      rec_ids = { record_id_field => record[record_id_field] }

      record_id_extra_fields&.each do |f|
        rec_ids[f] = record[f]
      end

      rec_ids
    end

    #
    # If Redcap records were previously transferred to the local database then
    # subsequently deleted, set them as disabled
    # @return [Array] of record identifier hashes, false or nil results
    def disable_deleted_records
      self.storage_stage = 'disable_deleted_records'
      update_job_request

      self.done = 0
      existing_not_in_retrieved_ids.each do |dbrec|
        record = existing_records.find_by(dbrec)
        self.done += 1
        update_job_request if done % step_count == 0

        next if record.disabled?

        record.disabled = true
        attrs = record.attributes
                      .reject { |k, _v| k.in?(%w[id created_at updated_at user_id]) }
                      .symbolize_keys

        res = create_or_update(attrs, keep_results: false)
        disabled_ids << res[record_id_field] if res
      end

      self.storage_stage = 'disable_deleted_records complete'
      update_job_request
    end

    #
    # Should we handle setting the master_id on a record?
    def do_handle_setting_master_id
      return @do_handle_setting_master_id unless @do_handle_setting_master_id.nil?

      @do_handle_setting_master_id = !!(@has_integer_survey_identifier && set_master_id_using_association)
    end

    #
    # If the project has the option set_master_id_using_association, update
    # the new/update record master_id value with the master_id returned from the
    # external id association.
    # @return [Integer | nil] - master_id if it was set, -1 if we don't handle setting the master id,
    #                           or nil if the record is to be skipped
    def handle_setting_master_id(update_record, retrieved_record)
      return -1 unless do_handle_setting_master_id

      isi = retrieved_record[external_id_fkey_name]
      recid = retrieved_record.first.last
      if !isi && !skip_store_if_no_survey_identifier
        raise FphsException,
              "Integer survey identifier field is empty, can't set master id, for record #{recid}"
      elsif isi
        # Start by setting the integer survey identifier field, so the association can get the master with the new value
        update_record[external_id_fkey_name] = isi
      elsif skip_store_if_no_survey_identifier
        # No survey identifier is returned and the project option skip_store_if_no_survey_identifier is set, so
        # just return with no result, indicating a skip.
        return
      end

      # Retrieve the master_id from the record (which goes through the association), then set the value returned
      # on the actual underlying attribute. Although this looks like it is assigning the same value, this is not
      # actually what is happening.
      res = update_record.master_id = update_record.master_id

      unless res
        raise FphsException,
              "Redcap pull failed to get master id through association, for record #{recid} with survey identifier #{isi}"
      end

      res
    end

    #
    # Handle creation of new record if the record does not already exist based on its
    # record_id_field matching, update if it does exist and has new information, or
    # do nothing if it exists and is unchanged.
    # Validations are applied to creates and updates and errors are returned within an
    # errors array. Callbacks (dynamic save triggers) are fired.
    # If an update or create is successful, return the record identifiers,
    # if there is no change return false
    # and if there is any other result (an error) return nil.
    # @param [Hash] record
    # @param [true | false] keep_results - save each existing or new record to @upserted_records
    # @return [Integer | false | nil]
    def create_or_update(retrieved_record, keep_results: true)
      rec_ids = record_identifiers(retrieved_record)
      attrs_for_persistence = retrieved_record.dup
      existing_record = model.where(rec_ids).first
      if existing_record
        existing_record.no_track = true if existing_record.respond_to? :no_track
        if existing_record.respond_to? :current_user=
          existing_record.current_user = current_user
        else
          Rails.logger.warn "Redcap::DataRecords#create_or_update: existing record #{model} doesn't respond to current_user"
        end

        # Check if there is an exact match for the record. If so, we are done
        if record_matches_retrieved(existing_record, retrieved_record)
          unchanged_ids << rec_ids
          return false
        end

        res = handle_setting_master_id(existing_record, retrieved_record)
        # No valid result, but no exception, so just skip this one
        unless res
          skipped_ids << rec_ids
          return
        end

        # Defer file field values until the actual file has been captured.
        # Persisting the filename string before capture_files runs leaves the
        # row inconsistent (filename present, no stored file) if anything
        # between the commit and capture_files raises - notably the
        # after_commit save trigger handlers. By nulling the field here and
        # writing the filename back via update_columns only after a successful
        # file import, a failed pull leaves the field NULL so the next pull
        # detects the mismatch and retries.
        pending_file_field_values = extract_and_null_file_fields(attrs_for_persistence)

        existing_record.force_save!
        if existing_record.update(attrs_for_persistence)
          stash_pending_file_fields(existing_record, pending_file_field_values)
          if keep_results
            updated_ids << rec_ids
            upserted_records << existing_record
          end
          return rec_ids
        else
          errors << { id: rec_ids, errors: existing_record.errors, action: :update }
        end
      else
        # See comment above on deferring file field values until capture_files
        # has actually stored the file.
        pending_file_field_values = extract_and_null_file_fields(attrs_for_persistence)

        new_record = model.new(attrs_for_persistence)
        new_record.no_track = true if new_record.respond_to? :no_track
        if new_record.respond_to? :current_user=
          new_record.current_user = current_user
        else
          Rails.logger.warn "Redcap::DataRecords#create_or_update: new record #{model} doesn't respond to current_user"
        end

        res = handle_setting_master_id(new_record, retrieved_record)
        unless res
          skipped_ids << rec_ids
          return
        end

        new_record.force_save!
        if new_record.save
          stash_pending_file_fields(new_record, pending_file_field_values)
          if keep_results
            created_ids << rec_ids
            upserted_records << new_record
          end
          return rec_ids
        else
          errors << { id: rec_ids, errors: new_record.errors, action: :create }
        end
      end

      nil
    end

    # Remove file field values from the retrieved record hash so the row is
    # persisted without filename strings for fields whose underlying files have
    # not yet been captured. Returns the removed { field_name => value } hash
    # to be replayed by #capture_files once the file is stored.
    # @param [Hash] retrieved_record - mutated in place
    # @return [Hash{Symbol => String}]
    def extract_and_null_file_fields(retrieved_record)
      pending = {}
      file_fields.each do |field_name|
        value = retrieved_record[field_name]
        next if value.blank?

        pending[field_name] = value
        retrieved_record[field_name] = nil
      end
      pending
    end

    # Attach the deferred file field values to the persisted AR record so
    # #capture_files can replay them after a successful file import.
    # @param [UserBase] record
    # @param [Hash{Symbol => String}] pending_file_field_values
    def stash_pending_file_fields(record, pending_file_field_values)
      record.instance_variable_set(:@_redcap_pending_file_fields, pending_file_field_values)
    end

    #
    # Capture files from file fields in the requested record, which typically represents
    # an updated or created dynamic model instance.
    # Files are only retrieved if the record includes a string entry in the
    # retrieved record field.
    # Once retrieved, files are stored in the project's filestore,
    # with the path: file-fields/<record id>
    # and file name: <field name>
    # @param [UserBase] record - the record to capture the file fields from
    def capture_files(record)
      self.done = 0
      pending_file_field_values = record.instance_variable_get(:@_redcap_pending_file_fields) || {}

      file_fields.each do |field_name|
        # Source the filename from the deferred values stashed before persistence,
        # falling back to the AR attribute (e.g. for retried/legacy rows where
        # the field already holds the filename string).
        filename_value = pending_file_field_values[field_name]
        filename_value = record[field_name] if filename_value.blank?
        next if filename_value.blank?

        self.done += 1
        update_job_request if done % step_count == 0

        record_id = record[record_id_field]
        begin
          # In order to retrieve files from longitudinal records (within events),
          # we need to pass the event name as well.
          # This is not required for classic instruments, since they do not have events, and will just be ignored.
          event = record[:redcap_event_name]

          temp_file = retrieve_file(record_id, field_name, event:)
          # We must change the permissions now, since the final NFS store
          # requires the group to have read-write.
          path = "#{project_admin.dynamic_model_table}/file-fields/#{record_id}"
          filename = field_name
          container = project_admin.file_store

          res = NfsStore::Import.import_file(container.id,
                                             filename,
                                             temp_file.path,
                                             current_user,
                                             path:,
                                             replace: true)
          if res
            imported_files << res
            # Now that the file is stored, write the deferred filename back to
            # the dynamic-model row. Use update_columns to skip validations and
            # callbacks so this does not re-fire after_commit save triggers.
            # Skip when record is not an AR instance (e.g. when capture_files
            # is called directly with a retrieved hash in tests).
            if record.respond_to?(:update_columns)
              record.update_columns(field_name => filename_value)
            else
              record[field_name] = filename_value
            end
          else
            # import_file returned nil: the file was skipped (e.g. an identical
            # stored_file row already existed, or skip_existing matched).
            # This can mask a missing-on-disk file when a stored_files row exists
            # but the underlying file is not actually present, so log everything
            # passed to import_file for diagnosis.
            Rails.logger.warn(
              'Redcap capture_files: NfsStore::Import.import_file returned nil (file skipped). ' \
              "container_id: #{container.id}, file_name: #{filename}, " \
              "file_path: #{temp_file.path}, user: #{current_user&.email}, " \
              "path: #{path}, replace: true, record_id: #{record_id}, " \
              "project_admin: #{project_admin.id}"
            )
          end
        rescue Exception => e
          # We rescue Exception rather than StandardError, since file errors inherit from Exception
          msg = "Failed to retrieve or import REDCap file for record: #{record_id} - field name: #{field_name} - with user: #{current_user.email}.\n#{e}"
          Rails.logger.warn msg
          errors << { id: record_id, errors: { capture_files: msg }, action: :capture_files }
          failed_files << { record_id:, field_name:, error: e.message }
          # Mark the file field with a searchable marker so that:
          # 1. It can be found in database queries to identify failed captures
          # 2. Future pulls with export_only_updated_records will retry these records
          record[field_name] = FailedFileFieldMarker
          record.update_columns(field_name => FailedFileFieldMarker)
          # Continue processing other files instead of raising
        ensure
          temp_file&.close
          temp_file&.unlink
        end
      end
    end

    #
    # Array of file field fieldnames
    # @return [Array{Symbol}]
    def file_fields
      data_dictionary.all_fields_of_type(:file).keys
    end

    #
    # Check if a stored record matches the retrieved record.
    # Care must be taken, since REDCap retrieved records have every
    # attribute as a string. A dynamic model may also have fields that are not
    # exclusively part of the data dictionary.
    # We cast retrieved record field value strings to real values for comparison
    # since this reduces the sensitivity of string comparisons. For example,
    # converting a number 243.0 and 243 should be equivalent, but string comparisons
    # will fail.
    # @param [Dynamic::DynamicModelBase] existing_record
    # @param [Hash{Symbol => String}] new_record
    # @return [true]
    def record_matches_retrieved(existing_record, new_record)
      new_attrs = new_record.dup
      existing_attrs = existing_record.attributes.symbolize_keys.dup
      existing_attrs.slice!(*all_data_dictionary_fields.keys)

      res = new_attrs.reject do |field_name, new_value|
        # We allow the field_name to return nothing from the fields, since attributes like
        # *disabled* can be updated in this way
        all_data_dictionary_fields[field_name]&.field_type&.values_match?(new_value, existing_attrs[field_name])
      end

      # Handle special case - if the option to set_master_id_using_association && the current master_id is not set
      # This will allow the lookup of the master to run by treating it as having changed.
      res[:master_id] = true if set_master_id_using_association && existing_record['master_id'].nil?

      # Optionally verify that each file field's underlying stored file is
      # actually present in the project's filestore container. When a file is
      # missing on disk (no nfs_store_stored_files row at the expected path /
      # file_name) we treat the record as changed, so capture_files retries.
      # This is only enabled when explicitly requested for a manual pull, since
      # it adds overhead to record comparison.
      if verify_file_fields && res.empty?
        missing = file_fields.find do |field_name|
          existing_value = existing_attrs[field_name]
          next false if existing_value.blank? || existing_value == FailedFileFieldMarker

          !stored_file_exists?(existing_record, field_name)
        end
        res[missing] = :stored_file_missing if missing
      end

      res.empty?
    end

    # Check whether a stored_files row exists in the project's filestore
    # container for the given record + file field, using a per-run memoized
    # index to keep this O(1).
    # @param [Dynamic::DynamicModelBase] existing_record
    # @param [Symbol] field_name
    # @return [Boolean]
    def stored_file_exists?(existing_record, field_name)
      record_id = existing_record[record_id_field]
      return false if record_id.blank?

      key = "#{project_admin.dynamic_model_table}/file-fields/#{record_id}/#{field_name}"
      stored_file_index.include?(key)
    end

    # Memoized Set of "<path>/<file_name>" entries for every stored_files row in
    # the project's filestore container, restricted to the file-fields path
    # prefix used by capture_files.
    # @return [Set<String>]
    def stored_file_index
      @stored_file_index ||= begin
        container = project_admin.file_store
        path_prefix = "#{project_admin.dynamic_model_table}/file-fields/"
        Set.new(
          container.stored_files
                   .where('path LIKE ?', "#{ActiveRecord::Base.sanitize_sql_like(path_prefix)}%")
                   .pluck(:path, :file_name)
                   .map { |path, file_name| "#{path}/#{file_name}" }
        )
      end
    end

    #
    # The current user to use for storing records and files
    # @return [User]
    def current_user
      @current_user ||= project_admin.current_user
    end

    #
    # Create or update job request record
    # @param [true | nil] create - optional - create a new record for this request
    def update_job_request(create: nil)
      result = {
        storage_stage:,
        count_retrieved: records&.length,
        count_created_ids: created_ids&.length,
        count_updated_ids: updated_ids&.length,
        count_unchanged_ids: unchanged_ids&.length,
        count_disabled_ids: disabled_ids&.length,
        count_skipped_ids: skipped_ids&.length,
        count_processed: done,
        table: project_admin.dynamic_model_table,
        errors:,
        imported_files_count: imported_files&.length,
        failed_files_count: failed_files&.length,
        job: job&.id,
        retrieved_from_cache:,
        using_date_range_filter:,
        date_range_begin: (date_range_begin if using_date_range_filter)
      }
      result[request_source] = true if request_source

      if create
        project_admin.record_job_request('store records', result:)
      else
        project_admin.update_job_request('store records', result:)
      end
    end
  end
end
