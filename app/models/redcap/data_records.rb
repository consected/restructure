# frozen_string_literal: true

module Redcap
  #
  # Handle and validate retrieved records
  # Works with the dynamic models created by Redcap::DynamicStorage, although this is not strictly required
  class DataRecords
    attr_accessor :project_admin, :records, :class_name, :errors, :created_ids, :updated_ids, :unchanged_ids,
                  :current_admin

    def initialize(project_admin, class_name)
      super()
      self.project_admin = project_admin
      self.class_name = class_name
      self.updated_ids = []
      self.created_ids = []
      self.unchanged_ids = []
      self.errors = []
      self.current_admin = project_admin.admin
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
      self.records = project_admin.api_client.records
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
        next if r.keys == all_expected_fields.keys

        raise FphsException,
              "Redcap::DataRecords retrieved record fields don't match the data dictionary:\n" \
              "[#{r.keys.join(' ')}]\nshould match the data dictionary\n[#{all_expected_fields.keys.join(' ')}]"
      end

      if records.length < existing_records_length
        raise FphsException,
              "Redcap::DataRecords retrieved fewer records (#{records.length}) " \
              "than expected (#{existing_records_length})"
      end

      existing_rec_ids = existing_records.pluck(record_id_field)
      retrieved_rec_ids = records.map { |r| r[record_id_field] }

      if retrieved_rec_ids.find(&:blank?)
        raise FphsException, 'Redcap::DataRecords retrieved data that has a nil record id'
      end

      existing_not_in_retrieved_ids = existing_rec_ids - retrieved_rec_ids
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
    def store
      records.each do |record|
        create_or_update record
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

    def create_or_update(record)
      record_id = record[record_id_field]
      existing_record = model.where(record_id_field => record_id).first

      if existing_record

        # Check if there is an exact match for the record. If so, we are done
        if record_matches_retrieved(existing_record, record)
          unchanged_ids << record_id
          return
        end

        existing_record.force_save!
        if existing_record.update(record)
          updated_ids << record_id
        else
          errors << { id: record_id, errors: existing_record.errors, action: :update }
        end
      else
        new_record = model.new(record)
        new_record.force_save!
        if new_record.save
          created_ids << record_id
        else
          errors << { id: record_id, errors: new_record.errors, action: :create }
        end
      end
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
