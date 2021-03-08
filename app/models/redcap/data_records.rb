# frozen_string_literal: true

module Redcap
  #
  # Handle and validate retrieved records
  # Works with the dynamic models created by Redcap::DynamicStorage, although this is not strictly required
  class DataRecords
    attr_accessor :project_admin, :records, :class_name, :errors, :created_ids, :updated_ids, :unchanged_ids,
                  :current_admin, :retrieved_files, :upserted_records, :imported_files

    def initialize(project_admin, class_name)
      super()
      self.project_admin = project_admin
      self.class_name = class_name
      self.updated_ids = []
      self.created_ids = []
      self.unchanged_ids = []
      self.errors = []
      self.current_admin = project_admin.admin
      self.retrieved_files = {}
      self.upserted_records = []
      self.imported_files = []
    end

    #
    # Request a background job retrieve records and save them to the specified model
    # @see Redcap::CaptureRecordsJob#perform_later
    # @param [Redcap::ProjectAdmin] project_admin
    # @param [String] class_name - the class name for the model to store to
    def request_records
      Redcap::CaptureRecordsJob.perform_later(project_admin, class_name)
    end

    #
    # Immediately retrieve, validate and store the records from REDCap.
    # This is only intended to be called from a background job.
    def retrieve_validate_store
      retrieve
      validate
      store
    end

    #
    # Immediately retrieve records from REDCap.
    # This is only intended to be called from a background job.
    # @return [Array{Hash}]
    def retrieve
      self.records = project_admin.api_client.records request_options: project_admin.records_request_options
    end

    #
    # Immediately retrieve file from a REDCap file field for a
    # specific record. The most recent request is stored to the
    # retrieved_files Hash.
    # @return [Hash{Symbol => File}] <description>
    def retrieve_file(record_id, field_name)
      retrieved_files[field_name] = project_admin.api_client.file record_id, field_name
    end

    #
    # Perform validations on the records returned
    # We choose to fail with an exception for these, since any of them
    # represent bad data retrieved from Redcap, which could indicate corruption
    # of the data, which should not make it to the local database
    def validate
      unless records.is_a? Array
        raise FphsException, "Redcap::DataRecords did not return an array: #{records.class.name}"
      end

      return unless records.first

      unless records.first.is_a? Hash
        raise FphsException, "Redcap::DataRecords did not return a hash as first item: #{records.first.class.name}"
      end

      overlapping_fields = records.first.keys & model.attribute_names.map(&:to_sym)
      unless overlapping_fields.length == records.first.keys.length
        missing_fields = records.first.keys - model.attribute_names.map(&:to_sym)
        raise FphsException, "Redcap::DataRecords retrieved record fields are not present in the model:\n" \
                             "#{missing_fields.join(' ')}"
      end

      records.each do |r|
        next if r.keys.sort == all_expected_fields.keys.sort

        raise FphsException,
              "Redcap::DataRecords retrieved record fields don't match the data dictionary:\n" \
              "[#{r.keys.sort.join(' ')}]\nshould match the data dictionary\n[#{all_expected_fields.keys.sort.join(' ')}]"
      end

      if records.length < existing_records_length
        raise FphsException,
              "Redcap::DataRecords retrieved fewer records (#{records.length}) " \
              "than expected (#{existing_records_length})"
      end

      retrieved_rec_ids = records.map { |r| r[record_id_field] }

      if retrieved_rec_ids.find(&:blank?)
        raise FphsException, 'Redcap::DataRecords retrieved data that has a nil record id'
      end

      existing_rec_ids = existing_records.pluck(record_id_field).map(&:to_i)
      retrieved_rec_int_ids = retrieved_rec_ids.map(&:to_i)
      existing_not_in_retrieved_ids = existing_rec_ids - retrieved_rec_int_ids
      if existing_not_in_retrieved_ids.present?
        raise FphsException,
              'Redcap::DataRecords existing records were not in the retrieved records: ' \
              "#{existing_not_in_retrieved_ids.join(', ')}"
      end
    end

    #
    # Store (upsert) each of the retrieved records into the named model.
    # This is done iteratively, to ensure that callbacks are fired.
    # Error will appear in #errors
    # IDs of created items will appear in #created_ids
    # IDs of updated items will appear in #updated_ids
    # For each updated or created record, also download the file fields to the
    # associated file store
    def store
      upserts = []

      records.each do |record|
        res = create_or_update record
        upserts << res if res
      end

      upserted_records.each do |record|
        capture_files record
      end

      result = {
        created_ids: created_ids,
        updated_ids: updated_ids,
        unchanged_ids: unchanged_ids,
        errors: errors
      }

      ClientRequest.create! current_admin: current_admin,
                            action: 'store records',
                            server_url: project_admin.server_url,
                            name: project_admin.name,
                            redcap_project_admin: project_admin,
                            result: result
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

    private

    def data_dictionary
      project_admin.redcap_data_dictionary
    end

    #
    # The sequential record_id field is not a fixed name. Get it from the data dictionary
    # @return [Symbol]
    def record_id_field
      data_dictionary.record_id_field
    end

    #
    # All fields expected to be retrieved from REDCap to be stored as a record
    # @return [Hash{Symbol => Redcap::DataDictionaries::Field}]
    def all_expected_fields
      @all_expected_fields ||= data_dictionary.all_retrievable_fields
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
    # Handle creation of new record if the record does not already exist based on its
    # record_id_field matching, update if it does exist and has new information, or
    # do nothing if it exists and is unchanged.
    # Validations are applied to creates and updates and errors are returned within an
    # errors array. Callbacks (dynamic save triggers) are fired.
    # If an update or create is successful, return the record_id, if there is no change return false
    # and if there is any other result (an error) return nil.
    # @param [Hash] record
    # @return [Integer | false | nil]
    def create_or_update(record)
      record_id = record[record_id_field]
      existing_record = model.where(record_id_field => record_id).first

      if existing_record

        # Check if there is an exact match for the record. If so, we are done
        if record_matches_retrieved(existing_record, record)
          unchanged_ids << record_id
          return false
        end

        existing_record.force_save!
        if existing_record.update(record)
          updated_ids << record_id
          upserted_records << existing_record
          return record_id
        else
          errors << { id: record_id, errors: existing_record.errors, action: :update }
        end
      else
        new_record = model.new(record)
        new_record.force_save!
        if new_record.save
          created_ids << record_id
          upserted_records << new_record
          return record_id
        else
          errors << { id: record_id, errors: new_record.errors, action: :create }
        end
      end

      nil
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
      file_fields.each do |field_name|
        next if record[field_name].blank?

        record_id = record[record_id_field]
        begin
        temp_file = retrieve_file(record_id, field_name)
        path = "file-fields/#{record_id}"
        filename = field_name
        container = project_admin.file_store
        current_user = project_admin.current_user

        
          res = NfsStore::Import.import_file(container.id,
                                             filename,
                                             temp_file.path,
                                             current_user,
                                             path: path,
                                             replace: true)
          imported_files << res if res
        rescue RestClient::BadRequest => e
          msg = "Failed to retrieve or import REDCap file #{record_id} #{field_name}"
          Rails.logger.warn msg
          errors << { id: record_id, errors: { capture_files: msg }, action: :capture_files }

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
    # @param [Hash{Symbol => String}] record
    # @return [true]
    def record_matches_retrieved(existing_record, record)
      check_rec = record.dup
      attrs = existing_record.attributes.symbolize_keys.dup
      attrs.slice!(*all_expected_fields.keys)

      check_rec.each do |field_name, value|
        check_rec[field_name] = all_expected_fields[field_name].field_type.cast_value_to_real(value)
      end

      check_rec == attrs
    end
  end
end
