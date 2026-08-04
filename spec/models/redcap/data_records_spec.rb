# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::DataRecords, type: :model do
  include MasterSupport
  include ModelSupport
  include Redcap::RedcapSupport

  def request_admin
    res = Admin.find_active_by_email_or_id Settings::RedcapJobUserEmail
    expect(res).to be_a Admin
    res
  end

  def create_sid_scantrons
    @record_ids = %w[1 4 14 19 32]
    @int_survey_ids = @record_ids.map { |i| "12#{i}".to_i } + @record_ids.map { |i| "2#{i}".to_i }
    @int_survey_ids.each do |sid|
      master = create_master(@user)
      master.current_user = @user
      master.scantrons.create!(scantron_id: sid)
    end
  end

  def clean_file_fields_filesystem(container)
    FileUtils.rm_rf "#{NfsStore::Manage::Filesystem.nfs_store_directory}/gid601/app-type-#{container.app_type_id}/containers/#{container.id} -- q2_demo/redcap_test.test_file_field_recs/file-fields/"
  end

  before :all do
    change_setting('AllowDynamicMigrations', true)
  end

  describe 'retrieving records and files' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first
      @metadata_project = @projects.find { |p| p[:name] == 'metadata' }
      setup_file_fields
    end

    before :example do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      change_setting('RedcapJobUserEmail', @admin.email)
      setup_file_store
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first
      reset_mocks
    end

    it 'has a valid model to store records to, which must be a subclass of Dynamic::DynamicModelBase' do
      setup_file_fields

      dmrec = DynamicModel.active.find_by(category: 'redcap')
      dmrec.force_regenerate = true
      dmrec.generate_model
      DynamicModel.reset_active_model_configurations!

      dm = dmrec.implementation_class
      expect(dm < Dynamic::DynamicModelBase).to be true

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      class_name = dm.name
      dr = Redcap::DataRecords.new(rc, class_name)

      expect { dr.send :model }.not_to raise_error

      dr = Redcap::DataRecords.new(rc, 'Class')

      expect { dr.send :model }.to raise_error(FphsException, 'Redcap::DataRecords model is not a valid type: Class')
    end

    it 'retrieves records from REDCap immediately' do
      dm = create_dynamic_model_for_sample_response

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      res = dr.retrieve

      expect(res).to be_a Array
      expect(res.length).to eq 5
      expect(res.first).to be_a Hash
      expect(res.first.keys.first).to eq :record_id
    end

    it 'validates retrieved records' do
      dm = create_dynamic_model_for_sample_response

      # data_sample_response_fields

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect { dr.validate }.not_to raise_error
    end

    it 'raises errors if retrieved records id is missing' do
      dm = create_dynamic_model_for_sample_response

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      stub_request_records @project[:server_url], @project[:api_key], 'fail_record_id_nil'
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier
      expect { dr.validate }.to raise_error(FphsException, 'Redcap::DataRecords retrieved data that has a nil record id')
    end

    it 'raises errors if retrieved records have missing fields' do
      dm = create_dynamic_model_for_sample_response

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      stub_request_records @project[:server_url], @project[:api_key], 'mismatch_fields'
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier
      expect do
        dr.validate
      end.to raise_error(FphsException,
                         "Redcap::DataRecords::ModelMissingFields retrieved record fields are not present in the model:\nmismatch_field")
    end

    it 'stores retrieved records' do
      dm = create_dynamic_model_for_sample_response

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      stub_request_records @project[:server_url], @project[:api_key]
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect { dr.validate }.not_to raise_error

      dr.store

      expect(dr.errors).to be_empty
      expect(dr.created_ids.map { |r| r[:record_id] }.sort).to eq %w[1 4 14 19 32].sort
      expect(dr.updated_ids).to be_empty
    end

    it "fails if survey fields are requested and the dynamic model doesn't expect them" do
      dm = create_dynamic_model_for_sample_response

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.records_request_options.exportSurveyFields = true

      stub_request_records @project[:server_url], @project[:api_key]
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      expect { dr.validate }.to raise_error FphsException,
                                            "Redcap::DataRecords::ModelMissingFields retrieved record fields are not present in the model:\n" \
                                            'redcap_survey_identifier q2_survey_timestamp test_timestamp'
    end

    it 'stores retrieved records even if the target has additional fields' do
      dm = create_dynamic_model_for_sample_response

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      WebMock.reset!

      mock_limited_requests
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

      api_key = rc.api_key
      rc.update! current_admin: @admin, disabled: true
      rc = Redcap::ProjectAdmin.create! current_admin: @admin,
                                        study: 'Q2',
                                        name: 'q2_demo',
                                        api_key:,
                                        server_url: rc.server_url

      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect { dr.validate }.not_to raise_error

      dr.store

      expect(dr.errors).to be_empty
      expect(dr.created_ids.map { |r| r[:record_id] }.sort).to eq %w[1 19 32 4 5].sort
      expect(dr.updated_ids).to be_empty
    end

    it 'raises an error if the retrieved fields are different from the expect fields' do
    end

    it 'does nothing if the records all match' do
      dm = create_dynamic_model_for_sample_response

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      stub_request_records @project[:server_url], @project[:api_key]
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect { dr.validate }.not_to raise_error

      dr.store

      expect(dr.errors).to be_empty
      expect(dr.created_ids.map { |r| r[:record_id] }.sort).to eq %w[1 4 14 19 32].sort
      expect(dr.updated_ids).to be_empty

      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect { dr.validate }.not_to raise_error

      dr.store

      expect(dr.errors).to be_empty
      expect(dr.created_ids.sort).to be_empty
      expect(dr.updated_ids).to be_empty
    end

    it 'does updates on records that have changed' do
      dm = create_dynamic_model_for_sample_response(survey_fields: true)

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.records_request_options.exportSurveyFields = true

      stub_request_records @project[:server_url], @project[:api_key]
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect { dr.validate }.not_to raise_error

      dr.store

      expect(dr.errors).to be_empty
      expect(dr.created_ids.map { |r| r[:record_id] }.sort).to eq %w[1 4 14 19 32].sort
      expect(dr.updated_ids).to be_empty

      WebMock.reset!
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)

      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

      stub_request_records @project[:server_url], @project[:api_key], 'updated_records'

      Rails.cache.clear
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect { dr.validate }.not_to raise_error
      dr.store

      expect(dr.errors).to be_empty
      expect(dr.created_ids).to be_empty
      expect(dr.updated_ids.map { |r| r[:record_id] }.sort).to eq %w[1 4 14 19].sort
    end

    it 'retrieves all records in the background' do
      dm = create_dynamic_model_for_sample_response
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.dynamic_model_table = dm.implementation_class.table_name.to_s
      rc.save # to ensure the background job works
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      start_time = DateTime.now
      expect(dm.implementation_class_defined?)

      expect(dr.existing_records_length).to eq 0

      dr.request_records

      expect(dr.existing_records_length).to be > 0

      cr = Redcap::ClientRequest.where(admin: @admin,
                                       action: 'store records',
                                       server_url: rc.server_url,
                                       name: rc.name,
                                       redcap_project_admin: rc)
                                .where('created_at > :created_at', created_at: start_time)
                                .last

      expect(cr.result).to be_a Hash
      expect(cr.result['storage_stage']).to be_present
      expect(cr.result['count_retrieved']).to be > 0
      expect(cr.result['count_created_ids']).to be > 0
      expect(cr.result['count_updated_ids']).to eq 0
      expect(cr.result['count_unchanged_ids']).to eq 0
      expect(cr.result['count_disabled_ids']).to eq 0
      expect(cr.result['count_skipped_ids']).to eq 0
      expect(cr.result['count_processed']).to be > 0
      expect(cr.result['table']).to eq dm.table_name
      expect(cr.result['errors']).to be_empty
      expect(cr.result['imported_files_count']).to eq 0
      expect(cr.result['failed_files_count']).to eq 0
      expect(cr.result).to have_key('job')
    end

    it 'retrieves all records in the background if there are more model than storage fields' do
      dm = create_dynamic_model_for_sample_response
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.dynamic_model_table = dm.implementation_class.table_name.to_s
      rc.save # to ensure the background job works

      WebMock.reset!

      mock_limited_requests
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)
      api_key = rc.api_key
      rc.update! current_admin: @admin, disabled: true
      rc = Redcap::ProjectAdmin.create! current_admin: @admin,
                                        study: 'Q2',
                                        name: 'q2_demo',
                                        api_key:,
                                        server_url: rc.server_url

      rc.update! current_admin: @admin, dynamic_model_table: dm.implementation_class.table_name.to_s

      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      start_time = DateTime.now
      expect(dm.implementation_class_defined?)

      expect(dr.existing_records_length).to eq 0

      dr.request_records

      expect(dr.existing_records_length).to be > 0

      cr = Redcap::ClientRequest.where(action: 'store records',
                                       server_url: rc.server_url,
                                       name: rc.name,
                                       redcap_project_admin: rc)
                                .where('created_at > :created_at', created_at: start_time)
                                .last

      if cr.nil?
        req = {
          admin: request_admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          created_at: start_time
        }
        puts "About to fail - no ClientRequest found for #{req}"
        Redcap::ClientRequest.where(redcap_project_admin: rc).where('created_at > :created_at', created_at: start_time).each do |r|
          puts "  Found ClientRequest #{r.attributes}"
        end
      end
      expect(cr).to be_present, "No ClientRequest found. Available: #{Redcap::ClientRequest.where(redcap_project_admin: rc).where('created_at > :created_at', created_at: start_time).pluck(:action).join(', ')}"
      expect(cr.result).to be_a Hash
      expect(cr.result['storage_stage']).to be_present
      expect(cr.result['count_retrieved']).to be > 0
      expect(cr.result['count_created_ids']).to be > 0
      expect(cr.result['count_updated_ids']).to eq 0
      expect(cr.result['count_unchanged_ids']).to eq 0
      expect(cr.result['count_disabled_ids']).to eq 0
      expect(cr.result['count_skipped_ids']).to eq 0
      expect(cr.result['count_processed']).to be > 0
      expect(cr.result['table']).to be_present
      expect(cr.result['errors']).to be_empty
      expect(cr.result['imported_files_count']).to eq 0
      expect(cr.result['failed_files_count']).to eq 0
      expect(cr.result).to have_key('job')
    end

    it 'fails to start background request if model has missing fields' do
      dm = create_dynamic_model_for_sample_response
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.dynamic_model_table = dm.implementation_class.table_name.to_s
      rc.save # to ensure the background job works

      WebMock.reset!

      WebMock.reset!
      mock_limited_requests
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)
      stub_request_records @project[:server_url], @project[:api_key], 'missing_record'

      api_key = rc.api_key
      rc.update! current_admin: @admin, disabled: true
      rc = Redcap::ProjectAdmin.create! current_admin: @admin,
                                        study: 'Q2',
                                        name: 'q2_demo',
                                        api_key:,
                                        server_url: rc.server_url

      rc.update! current_admin: @admin, dynamic_model_table: dm.implementation_class.table_name.to_s

      Redcap::ClientRequest.where(action: 'store records',
                                  server_url: rc.server_url,
                                  name: rc.name,
                                  redcap_project_admin: rc)
                           .last

      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      start_time = Time.now
      expect(dm.implementation_class_defined?)

      expect(dr.existing_records_length).to eq 0

      expect { dr.request_records }.to raise_error FphsException, /Redcap::DataRecords::MismatchFields retrieved record fields don't match the data dictionary:/

      expect(dr.existing_records_length).to eq 0

      cr = Redcap::ClientRequest.where(action: 'store records',
                                       server_url: rc.server_url,
                                       name: rc.name,
                                       redcap_project_admin: rc)
                                .where('created_at > :created_at', created_at: start_time)
                                .last

      expect(cr.result['storage_stage']).to eq 'validate (failed)'

      cr = Redcap::ClientRequest.where(action: 'capture records job',
                                       server_url: rc.server_url,
                                       name: rc.name,
                                       redcap_project_admin: rc)
                                .where('created_at > :created_at', created_at: start_time)
                                .last
      expect(cr.result['error']).to include "Redcap::DataRecords::MismatchFields retrieved record fields don't match the data dictionary"
    end

    it 'downloads files' do
      setup_file_fields
      rc = @project_admin
      rc.current_admin = @admin
      setup_file_store rc.job_admin
      setup_file_store

      # expect(@admin.matching_user).to eq @user
      expect(@user.has_access_to?(:edit, :table, rc.dynamic_storage.dynamic_model.resource_name))
      expect(@user.role_names).to include(Settings.admin_nfs_role)
      puts @user.email

      # Debug: Check what user the data_records will use
      rc.current_user
      # puts "DataRecords current_user: #{dr_user&.email}"
      # puts "DataRecords current_user has edit access to stored_files: #{dr_user&.has_access_to?(:edit, :table, 'nfs_store__manage__stored_files')}"
      # puts "DataRecords current_user app_type: #{dr_user&.app_type&.name}"
      # puts "@user app_type: #{@user.app_type&.name}"

      rc.redcap_data_dictionary
      clean_file_fields_filesystem rc.file_store

      dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')

      expect(dr.send(:file_fields)).to eq %i[file1 signature]

      dr.retrieve
      expect(dr.records.length).to be > 0
      puts dr.errors if dr.errors.present?
      expect(dr.errors).not_to be_present

      dr.send(:capture_files, dr.records[1])
      puts dr.errors if dr.errors.present?
      expect(dr.errors).not_to be_present

      files = dr.imported_files
      expect(files.count).to eq 2
      expect(files.map { |f| "#{f.path}/#{f.file_name}" }.sort).to eq ["#{rc.dynamic_model_table}/file-fields/4/file1", "#{rc.dynamic_model_table}/file-fields/4/signature"]

      # Repeat - should not update the files
      Rails.cache.clear
      dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
      dr.retrieve
      dr.send(:capture_files, dr.records[1])
      expect(dr.errors).not_to be_present
      files = dr.imported_files
      expect(files.count).to eq 0

      # Reset with new file content
      Rails.cache.clear
      mock_file_field_requests
      dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
      dr.retrieve
      dr.send(:capture_files, dr.records[1])
      expect(dr.errors).not_to be_present
      files = dr.imported_files
      expect(files.count).to eq 2
    end

    it 'tracks failed file imports' do
      setup_file_fields
      rc = @project_admin
      rc.current_admin = @admin
      setup_file_store rc.job_admin
      setup_file_store

      expect(@user.has_access_to?(:edit, :table, rc.dynamic_storage.dynamic_model.resource_name))
      expect(@user.role_names).to include(Settings.admin_nfs_role)

      clean_file_fields_filesystem rc.file_store

      # Mock REDCap API file retrieval
      mock_file_field_requests

      # Mock file import to fail for file1 but succeed for signature
      call_count = 0
      allow(NfsStore::Import).to receive(:import_file).and_wrap_original do |method, *args, **kwargs|
        call_count += 1
        filename_str = args[1].to_s
        raise StandardError, "Simulated file import failure for #{filename_str}" if filename_str == 'file1'

        # Simulate a file import failure

        # Call original method with all arguments
        result = method.call(*args, **kwargs)
        result
      end

      dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
      dr.retrieve
      expect(dr.records.length).to be > 0

      # Identify the retrieved record that has both file fields BEFORE
      # create_or_update mutates the hash to NULL out file fields.
      retrieved_with_files = dr.records.find { |r| r[:file1].present? && r[:signature].present? }
      expect(retrieved_with_files).to be_present
      target_record_id = retrieved_with_files[dr.send(:record_id_field)]

      # Create/update records first so we have ActiveRecord instances
      dr.records.each do |record|
        dr.send(:create_or_update, record)
      end

      # Find the AR record corresponding to the retrieved record that had both
      # file fields. After create_or_update the column values are NULL, so we
      # locate it by record_id and verify via the stashed pending values.
      model_record = dr.upserted_records.find { |r| r[dr.send(:record_id_field)] == target_record_id }
      expect(model_record).to be_present
      pending = model_record.instance_variable_get(:@_redcap_pending_file_fields)
      expect(pending[:file1]).to be_present
      expect(pending[:signature]).to be_present

      dr.send(:capture_files, model_record)

      # Check that we have both successful and failed files
      expect(dr.imported_files.count).to eq 1 # signature succeeded
      expect(dr.failed_files.count).to eq 1 # file1 failed
      expect(dr.failed_files.first[:field_name]).to eq :file1
      expect(dr.failed_files.first[:error]).to include 'Simulated file import failure'
      expect(dr.errors.count).to eq 1
      expect(dr.errors.first[:action]).to eq :capture_files

      # Verify the file field was marked with FailedFileFieldMarker in the database record
      model_record.reload
      expect(model_record.file1).to eq Redcap::DataRecords::FailedFileFieldMarker
      expect(model_record.signature).to be_present
    end

    # Production regression: when a dynamic-model row has a blank file-field column
    # but the underlying stored_file row already exists (e.g. from a previous pull
    # that succeeded at the filestore level but did not write the filename back),
    # the next pull detects the mismatch (DB blank vs REDCap non-blank) and calls
    # capture_files again. NfsStore::Import.import_file returns nil because the file
    # hash matches the existing stored_file row, so the import is skipped. Without
    # the fix, the column stays blank and the loop repeats indefinitely.
    # With the fix, capture_files writes the filename to the column even on a skip.
    it 'writes filename to column when import_file skips because file already exists' do
      setup_file_fields
      rc = @project_admin
      rc.current_admin = @admin
      setup_file_store rc.job_admin
      setup_file_store
      clean_file_fields_filesystem rc.file_store
      mock_file_field_requests

      # First pull: import the files normally so the stored_file row exists.
      dr1 = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
      dr1.retrieve
      retrieved = dr1.records.find { |r| r[:file1].present? && r[:signature].present? }
      expect(retrieved).to be_present
      original_file1 = retrieved[:file1]
      dr1.records.each { |r| dr1.send(:create_or_update, r) }
      model_record = dr1.upserted_records.find { |r| r[dr1.send(:record_id_field)] == retrieved[dr1.send(:record_id_field)] }
      expect(model_record).to be_present
      dr1.send(:capture_files, model_record)
      expect(dr1.imported_files.count).to eq 2

      # Simulate the production symptom: blank the file-field column in the DB
      # while leaving the stored_file row in place.
      model_record.update_columns(file1: nil)
      model_record.reload
      expect(model_record.file1).to be_nil

      # Second pull: record comparison detects blank DB vs non-blank REDCap value,
      # so the record is treated as changed and flows through create_or_update.
      Rails.cache.clear
      mock_file_field_requests
      dr2 = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
      dr2.retrieve
      retrieved2 = dr2.records.find { |r| r[dr2.send(:record_id_field)] == model_record[dr2.send(:record_id_field)] }
      expect(retrieved2).to be_present
      dr2.records.each { |r| dr2.send(:create_or_update, r) }
      model_record2 = dr2.upserted_records.find { |r| r.id == model_record.id }
      expect(model_record2).to be_present

      # Simulate import_file returning nil (file hash matches existing stored_file —
      # the production scenario described in the regression). Only nil for file1;
      # allow signature to go through normally to confirm partial-skip works too.
      allow(NfsStore::Import).to receive(:import_file).and_wrap_original do |method, *args, **kwargs|
        next nil if args[1].to_s == 'file1'

        method.call(*args, **kwargs)
      end

      dr2.send(:capture_files, model_record2)

      # file1 was skipped (nil return), signature was imported normally
      expect(dr2.skipped_files.any? { |f| f[:field_name] == :file1 }).to be true
      expect(dr2.errors).to be_empty

      # The fix: file1 column should be written back even though import was skipped
      model_record2.reload
      expect(model_record2.file1).to eq original_file1
    end

    # The following specs verify that file field filenames are not persisted to
    # the dynamic-model row until the underlying file has actually been imported
    # to the NfsStore container. This avoids leaving the row in an inconsistent
    # state ("filename present, no file stored") if anything between the row
    # commit and capture_files raises - notably an after_commit save trigger.
    it 'defers persisting file field values until after the file has been captured' do
      setup_file_fields
      rc = @project_admin
      rc.current_admin = @admin
      setup_file_store rc.job_admin
      setup_file_store

      clean_file_fields_filesystem rc.file_store
      mock_file_field_requests

      dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
      dr.retrieve
      expect(dr.records.length).to be > 0

      # Find a retrieved record that has both file fields populated by REDCap
      retrieved = dr.records.find { |r| r[:file1].present? && r[:signature].present? }
      expect(retrieved).to be_present

      # Keep a copy of the original retrieved values. create_or_update now
      # persists from a dup hash, so the caller's retrieved hash remains
      # unchanged while file field values are deferred on persistence.
      pre_file1_value = retrieved[:file1]
      pre_signature_value = retrieved[:signature]

      dr.send(:create_or_update, retrieved)

      # After create_or_update but before capture_files, the row must have NULL
      # in each file field column, and the captured values must be stashed on
      # the AR instance for replay by capture_files.
      model_record = dr.upserted_records.last
      expect(model_record).to be_present

      model_record.reload
      expect(model_record.file1).to be_blank
      expect(model_record.signature).to be_blank

      pending = model_record.instance_variable_get(:@_redcap_pending_file_fields)
      expect(pending).to eq(file1: pre_file1_value, signature: pre_signature_value)

      # The retrieved hash remains unchanged (we only null on the persistence
      # copy), while the DB row itself stores NULL until capture_files runs.
      expect(retrieved[:file1]).to eq pre_file1_value
      expect(retrieved[:signature]).to eq pre_signature_value

      # Now run capture_files. The file is imported and the filename is written
      # back to the column via update_columns (no callbacks, no after_commit).
      dr.send(:capture_files, model_record)
      expect(dr.errors).not_to be_present
      expect(dr.imported_files.count).to eq 2

      model_record.reload
      expect(model_record.file1).to eq pre_file1_value
      expect(model_record.signature).to eq pre_signature_value
    end

    it 'leaves the file field NULL when capture_files is not invoked (simulating an after_commit failure)' do
      setup_file_fields
      rc = @project_admin
      rc.current_admin = @admin
      setup_file_store rc.job_admin
      setup_file_store

      clean_file_fields_filesystem rc.file_store
      mock_file_field_requests

      dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
      dr.retrieve

      retrieved = dr.records.find { |r| r[:file1].present? && r[:signature].present? }
      original_file1 = retrieved[:file1]
      original_signature = retrieved[:signature]

      dr.send(:create_or_update, retrieved)
      model_record = dr.upserted_records.last
      expect(model_record).to be_present

      # Simulate the failure mode where an after_commit save trigger raises
      # after the row is committed but before capture_files runs for this record.
      # capture_files is intentionally NOT invoked here.

      model_record.reload
      expect(model_record.file1).to be_blank
      expect(model_record.signature).to be_blank

      # On the next pull, REDCap returns the original filename strings; because
      # the DB row has NULL, record_matches_retrieved returns false and the
      # record is reprocessed, allowing capture_files to retry the import.
      Rails.cache.clear
      mock_file_field_requests
      dr2 = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
      dr2.retrieve
      retrieved2 = dr2.records.find { |r| r[:file1] == original_file1 && r[:signature] == original_signature }
      expect(retrieved2).to be_present

      dr2.send(:create_or_update, retrieved2)
      model_record2 = dr2.upserted_records.last
      expect(model_record2).to be_present
      expect(model_record2.id).to eq model_record.id

      dr2.send(:capture_files, model_record2)
      expect(dr2.errors).not_to be_present
      expect(dr2.imported_files.count).to eq 2

      model_record2.reload
      expect(model_record2.file1).to eq original_file1
      expect(model_record2.signature).to eq original_signature
    end

    # When the admin requests a manual pull with verify_file_fields: true, any
    # record whose dynamic-model row has a non-blank file field value but no
    # corresponding stored_files entry in the project's filestore container
    # should be treated as changed, so capture_files retries the file import.
    # This is a recovery option for legacy desynced rows; the option is
    # forced off for scheduled (non-manual) pulls to keep them fast.
    it 'verify_file_fields retries capture when a stored file is missing from the container' do
      setup_file_fields
      rc = @project_admin
      rc.current_admin = @admin
      setup_file_store rc.job_admin
      setup_file_store

      clean_file_fields_filesystem rc.file_store
      mock_file_field_requests

      # First, pull normally so file fields are captured and the dynamic-model
      # row has the filenames and the container has the stored_files rows.
      dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
      dr.retrieve
      retrieved = dr.records.find { |r| r[:file1].present? && r[:signature].present? }
      original_file1 = retrieved[:file1]
      original_signature = retrieved[:signature]
      dr.send(:create_or_update, retrieved)
      model_record = dr.upserted_records.last
      dr.send(:capture_files, model_record)
      expect(dr.errors).not_to be_present

      model_record.reload
      expect(model_record.file1).to eq original_file1
      expect(model_record.signature).to eq original_signature

      # Simulate the production symptom: delete the stored_files row(s) for
      # this record so the container no longer knows about the file. The
      # dynamic-model row still holds the filename.
      sf_path = "#{rc.dynamic_model_table}/file-fields/#{model_record[dr.send(:record_id_field)]}"
      sf_ids = rc.file_store.stored_files.where(path: sf_path).pluck(:id)
      ActiveRecord::Base.connection.execute(
        "DELETE FROM nfs_store_stored_file_history WHERE nfs_store_stored_file_id IN (#{sf_ids.join(',')})"
      )
      rc.file_store.stored_files.where(id: sf_ids).delete_all

      # Without verify_file_fields the next pull treats this record as
      # unchanged (filename matches between REDCap and DB), so the missing
      # file is not noticed and capture_files is not run.
      Rails.cache.clear
      mock_file_field_requests
      dr_default = Redcap::DataRecords.new(rc, 'TestFileFieldRec', is_manual_pull: true)
      dr_default.retrieve
      retrieved_default = dr_default.records.find { |r| r[:file1] == original_file1 && r[:signature] == original_signature }
      expect(retrieved_default).to be_present
      dr_default.send(:create_or_update, retrieved_default)
      expect(dr_default.upserted_records).to be_empty
      expect(dr_default.unchanged_ids).not_to be_empty

      # With verify_file_fields enabled, the missing stored file is detected
      # and the record flows through to capture_files. We assert the
      # detection-and-upsert behaviour here (the actual re-import side
      # effects are covered by other specs).
      Rails.cache.clear
      mock_file_field_requests
      dr_verify = Redcap::DataRecords.new(rc, 'TestFileFieldRec',
                                          is_manual_pull: true,
                                          verify_file_fields: true)
      dr_verify.retrieve
      retrieved_verify = dr_verify.records.find { |r| r[:file1] == original_file1 && r[:signature] == original_signature }
      expect(retrieved_verify).to be_present
      dr_verify.send(:create_or_update, retrieved_verify)
      expect(dr_verify.upserted_records).not_to be_empty
      reupserted = dr_verify.upserted_records.find { |r| r.id == model_record.id }
      expect(reupserted).to be_present
    end

    it 'verify_file_fields is forced off for scheduled (non-manual) pulls' do
      setup_file_fields
      rc = @project_admin
      rc.current_admin = @admin
      setup_file_store rc.job_admin
      setup_file_store

      dr_scheduled = Redcap::DataRecords.new(rc, 'TestFileFieldRec',
                                             is_manual_pull: false,
                                             verify_file_fields: true)
      expect(dr_scheduled.verify_file_fields).to be false

      dr_manual = Redcap::DataRecords.new(rc, 'TestFileFieldRec',
                                          is_manual_pull: true,
                                          verify_file_fields: true)
      expect(dr_manual.verify_file_fields).to be true
    end

    it 'downloads files in background' do
      rc = @project_admin
      rc.current_admin = @admin
      setup_file_store rc.job_admin
      setup_file_store

      # expect(@admin.matching_user).to eq @user
      expect(rc.job_user.has_access_to?(:edit, :table, rc.dynamic_storage.dynamic_model.resource_name)).to be_truthy
      expect(@user.role_names).to include(Settings.admin_nfs_role)
      expect(@user.has_access_to?(:create, :table, :nfs_store__manage__containers)).to be_truthy

      expect(rc.job_user.has_access_to?(:create, :table, :nfs_store__manage__containers)).to be_truthy

      puts @user.email

      expect(rc.dynamic_model_ready?).to be true

      files = rc.file_store.stored_files
      expect(files.count).to eq 0
      clean_file_fields_filesystem rc.file_store

      mock_file_field_requests

      rc.in_background_job = true
      rc.redcap_data_dictionary

      dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')

      dm = DynamicModel.active.find_by(table_name: 'test_file_field_recs')
      puts rc.dynamic_storage.dynamic_model.implementation_class.table_name
      puts DynamicModel.find_by(table_name: 'test_file_field_recs')&.attributes || 'no test_file_field_recs' unless dm
      puts DynamicModel.active.to_a unless dm
      expect(dm).to be_a DynamicModel

      expect(dr.existing_records_length).to eq 0
      dr.request_records
      expect(dr.existing_records_length).to be > 0

      puts dr.errors if dr.errors.present?
      expect(dr.errors).not_to be_present

      files = rc.file_store.stored_files.reload

      expect(files.count).to eq 4
      expect(files.map { |f| "#{f.path}/#{f.file_name}" }.sort)
        .to eq ["#{rc.dynamic_model_table}/file-fields/4/file1", "#{rc.dynamic_model_table}/file-fields/4/signature", "#{rc.dynamic_model_table}/file-fields/19/signature", "#{rc.dynamic_model_table}/file-fields/32/file1"].sort

      # Verify job result includes file counts
      start_time = DateTime.now - 1.minute
      cr = Redcap::ClientRequest.where(action: 'store records',
                                       server_url: rc.server_url,
                                       name: rc.name,
                                       redcap_project_admin: rc)
                                .where('created_at > :created_at', created_at: start_time)
                                .last

      expect(cr.result).to be_a Hash
      expect(cr.result['imported_files_count']).to eq 4
      expect(cr.result['failed_files_count']).to eq 0
    end
  end

  describe 'handling of deleted records prevents transfer' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first

      # Create the first DM not allowing records to be deleted
      rc = Redcap::ProjectAdmin.active.first
      rc.data_options.handle_deleted_records = nil
      rc.current_admin = @admin
      rc.save!

      ds = Redcap::DynamicStorage.new rc, "redcap_test.test_rc#{rand 100_000_000_000_000}_recs"
      ds.category = 'redcap-test-env'
      @dm = ds.create_dynamic_model
      expect(ds.dynamic_model_ready?).to be_truthy
    end

    before :example do
      create_admin
      setup_file_store
      reset_mocks
    end

    it 'complains if records are missing and handle_deleted_records = nil' do
      dm = create_dynamic_model_for_sample_response

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      stub_request_records @project[:server_url], @project[:api_key]
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      # Check we can retrieve and store in small steps
      dr.step_count = 3

      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect { dr.validate }.not_to raise_error

      dr.store

      expect(dr.errors).to be_empty
      expect(dr.created_ids.map { |r| r[:record_id] }.sort).to eq %w[1 4 14 19 32].sort
      expect(dr.updated_ids).to be_empty

      WebMock.reset!
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

      stub_request_records @project[:server_url], @project[:api_key], 'missing_record'
      Rails.cache.clear
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect do
        dr.validate
      end.to raise_error(FphsException, 'Redcap::DataRecords existing records were not in the retrieved records: {record_id: "4"}')
    end
  end

  describe 'handling of deleted records allows transfer' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first

      # Create the first DM not allowing records to be deleted
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.save!

      ds = Redcap::DynamicStorage.new rc, "redcap_test.test_rc#{rand 100_000_000_000_000}_recs"
      ds.category = 'redcap-test-env'
      @dm = ds.create_dynamic_model
      expect(ds.dynamic_model_ready?).to be_truthy
    end

    before :example do
      create_admin
      setup_file_store
      reset_mocks
    end

    it 'ignores records if records are missing and handle_deleted_records = ignore' do
      dm = create_dynamic_model_for_sample_response

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.data_options.handle_deleted_records = 'ignore'
      rc.save!
      expect(rc.data_options.handle_deleted_records).to eq 'ignore'
      expect(rc.ignore_deleted_records?).to be true

      stub_request_records @project[:server_url], @project[:api_key]
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect { dr.validate }.not_to raise_error

      dr.store

      expect(dr.errors).to be_empty
      expect(dr.created_ids.map { |r| r[:record_id] }.sort).to eq %w[1 4 14 19 32].sort
      expect(dr.updated_ids).to be_empty

      WebMock.reset!
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

      stub_request_records @project[:server_url], @project[:api_key], 'missing_record'
      Rails.cache.clear
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect do
        dr.validate
      end.not_to raise_error

      dr.store
      expect(dr.errors).to be_empty
      expect(dr.created_ids.map { |r| r[:record_id] }.sort).to eq %w[222224].sort
      expect(dr.updated_ids).to be_empty
    end

    it 'disables records if records are missing and handle_deleted_records = disable' do
      dm = create_dynamic_model_for_sample_response(disable: true)

      expect(dm.implementation_class.attribute_names).to include 'disabled'

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.data_options.handle_deleted_records = 'disable'
      rc.save!
      expect(rc.data_options.handle_deleted_records).to eq 'disable'
      expect(rc.disable_deleted_records?).to be true

      stub_request_records @project[:server_url], @project[:api_key]
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect { dr.validate }.not_to raise_error

      dr.store

      expect(dr.errors).to be_empty
      expect(dr.created_ids.map { |r| r[:record_id] }.sort).to eq %w[1 4 14 19 32].sort
      expect(dr.updated_ids).to be_empty

      WebMock.reset!
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)
      rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

      stub_request_records @project[:server_url], @project[:api_key], 'missing_record'
      Rails.cache.clear
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect do
        dr.validate
      end.not_to raise_error

      dr.store

      expect(dr.errors).to be_empty
      expect(dr.created_ids.map { |r| r[:record_id] }.sort).to eq %w[222224]
      expect(dr.updated_ids.map { |r| r[:record_id] }.sort).to eq %w[]
      expect(dr.disabled_ids.map { |r| r }.sort).to eq %w[4]

      expect(dm.implementation_class.find_by(record_id: 4)&.disabled).to be true
    end
  end

  describe 'project with summary choice array fields' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first

      # Create the first DM with multiple choice summary fields
      rc = Redcap::ProjectAdmin.active.first
      rc.data_options.add_multi_choice_summary_fields = true
      rc.current_admin = @admin
      rc.save!

      ds = Redcap::DynamicStorage.new rc, "redcap_test.test_rc#{rand 100_000_000_000_000}_recs"
      ds.category = 'redcap-test-env'
      @dm = ds.create_dynamic_model
      expect(ds.dynamic_model_ready?).to be_truthy
    end

    before :example do
      create_admin
      reset_mocks
    end

    it 'saves records with summary arrays' do
      dm = @dm

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.data_options.add_multi_choice_summary_fields = true
      rc.save!
      expect(rc.data_options.add_multi_choice_summary_fields).to be true
      dd = rc.redcap_data_dictionary
      all_rf_summ = dd.all_retrievable_fields(summary_fields: true)
      expect(all_rf_summ[:smoketime_chosen_array].field_type.name).to eq :checkbox_chosen_array

      stub_request_records @project[:server_url], @project[:api_key]

      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect(dr.records.first.keys).to include(:smoketime_chosen_array)

      expect { dr.validate }.not_to raise_error
      dr.store

      expect(dr.errors).to be_empty
      created_record_ids = dr.created_ids.map { |r| r[:record_id] }.sort
      expect(created_record_ids).to eq %w[1 4 14 19 32].sort
      expect(dr.updated_ids).to be_empty

      stored_recs = dm.implementation_class.where(record_id: created_record_ids)
      stored_recs.each do |r|
        sa = r.smoketime_chosen_array

        # Get the actual choices
        exp_array = %w[pnfl dnfl ANFL].map { |choice| r["smoketime___#{choice.downcase}"] && choice }.select { |item| item }
        expect(sa).to eq exp_array
      end

      dmic = dr.send :model
      #  Check we have a record that will exercise the uppercase choice
      res = dmic.where(smoketime___anfl: 1)
      expect(res.count).to be > 0

      # Now test all records to ensure choices in the summary array and the columns match
      # paying extra attention to those where the choice is uppercase in the definition
      # and therefore would have a column name (always downcased) that doesn't simply match the
      # uppercase value retrieved from Redcap and subsequently stored to the summary array field.
      res = dmic.all
      all_choices = %w[pnfl dnfl ANFL]
      matched = 0
      res.each do |r|
        all_choices.each do |choice|
          colval = r["smoketime___#{choice.downcase}"]
          expect(colval).not_to be_nil, "Column smoketime___#{choice.downcase} should not be nil for record #{r.record_id}"
          if colval
            expect(r.smoketime_chosen_array).to include choice
            matched += 1
          end
        end
      end

      expect(matched).to be > 0
    end
  end

  describe 'project associating foreign key with external id' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first

      # Create the first DM with integer survey identifier field
      rc = Redcap::ProjectAdmin.active.first
      rc.records_request_options.exportSurveyFields = true
      rc.data_options.associate_master_through_external_identifer = 'scantrons'
      rc.study = 'external-id-test'
      rc.current_admin = @admin
      rc.save!

      rc.reload
      expect(rc.data_options.associate_master_through_external_identifer).to eq 'scantrons'
      puts "rc.id: #{rc.id}"

      ds = Redcap::DynamicStorage.new rc, "redcap_test.test_rc#{rand 100_000_000_000_000}_recs"
      ds.category = 'redcap-test-env'
      @dm = ds.create_dynamic_model
      expect(ds.dynamic_model_ready?).to be_truthy
    end

    before :example do
      create_admin
      setup_file_store
      reset_mocks

      # Set up scantrons to match to redcap_survey_identifiers
      setup_access :scantrons unless @user.has_access_to? :create, :table, :scantrons

      create_sid_scantrons
    end

    it 'saves records with integer survey identifiers' do
      dm = @dm

      rc = Redcap::ProjectAdmin.active.find_by(study: 'external-id-test')
      rc.current_admin = @admin
      rc.save!
      expect(rc.data_options.associate_master_through_external_identifer).to eq 'scantrons'
      dd = rc.redcap_data_dictionary
      all_rf = dd.all_retrievable_fields
      expect(all_rf[:redcap_survey_identifier_id].field_type.name).to eq :integer_survey_identifier

      stub_request_records @project[:server_url], @project[:api_key]
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect(dr.records.first.keys).to include(:redcap_survey_identifier_id)

      expect { dr.validate }.not_to raise_error
      dr.store

      expect(dr.errors).to be_empty
      created_record_ids = dr.created_ids.map { |r| r[:record_id] }.sort
      expect(created_record_ids).to eq @record_ids.sort
      expect(dr.updated_ids).to be_empty

      stored_recs = dm.implementation_class.where(record_id: created_record_ids)
      stored_recs.each do |r|
        sa = r.redcap_survey_identifier_id

        expect(sa).to eq r.redcap_survey_identifier.to_i
      end
    end
  end

  describe 'project associating foreign key with external id and setting master_id field' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first

      # Create the first DM with master_id
      rc = Redcap::ProjectAdmin.active.first
      rc.records_request_options.exportSurveyFields = true
      rc.data_options.associate_master_through_external_identifer = 'scantrons'
      rc.data_options.set_master_id_using_association = true
      rc.study = 'external-id-test'
      rc.current_admin = @admin
      rc.save!

      rc.reload
      expect(rc.data_options.associate_master_through_external_identifer).to eq 'scantrons'
      puts "rc.id: #{rc.id}"

      ds = Redcap::DynamicStorage.new rc, "redcap_test.test_rc#{rand 100_000_000_000_000}_recs"
      ds.category = 'redcap-test-env'
      @dm = ds.create_dynamic_model
      expect(ds.dynamic_model_ready?).to be_truthy
      expect(@dm.field_list).to include('master_id')
    end

    before :example do
      create_admin
      setup_file_store
      reset_mocks

      # Set up scantrons to match to redcap_survey_identifiers
      setup_access :scantrons unless @user.has_access_to? :create, :table, :scantrons

      create_sid_scantrons
    end

    it 'saves records with integer survey identifiers and associated master_id' do
      dm = @dm

      rc = Redcap::ProjectAdmin.active.find_by(study: 'external-id-test')
      rc.current_admin = @admin
      rc.save!
      expect(rc.data_options.associate_master_through_external_identifer).to eq 'scantrons'
      dd = rc.redcap_data_dictionary
      all_rf = dd.all_retrievable_fields
      expect(all_rf[:redcap_survey_identifier_id].field_type.name).to eq :integer_survey_identifier

      stub_request_records @project[:server_url], @project[:api_key]
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier

      expect(dr.records.first.keys).to include(:redcap_survey_identifier_id)

      expect { dr.validate }.not_to raise_error
      dr.store

      expect(dr.errors).to be_empty
      created_record_ids = dr.created_ids.map { |r| r[:record_id] }.sort
      expect(created_record_ids).to eq @record_ids.sort
      expect(dr.updated_ids).to be_empty

      stored_recs = dm.implementation_class.where(record_id: created_record_ids)
      stored_recs.each do |r|
        sa = r.redcap_survey_identifier_id

        expect(sa).to eq r.redcap_survey_identifier.to_i
        expect(r['master_id']).to eq r.master.id
      end

      # Retrieving again makes no changes
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier
      dr.store

      expect(dr.updated_ids).to be_empty
      expect(dr.created_ids).to be_empty

      # Force a change in a master_id
      stored_recs = dm.implementation_class.where(record_id: created_record_ids)
      rec = stored_recs.first
      rec.force_save!
      rec.update!(current_user: @user, master_id: nil)

      # Retrieving again makes the changes
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier
      dr.store

      expect(dr.updated_ids.length).to eq 1
      expect(dr.created_ids).to be_empty

      # Now check an error is raised if no survey identifier is provided
      # Retrieving again - no changes yet

      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      # Force a change to the retrieved records
      orig_rcsid = dr.records.first[:redcap_survey_identifier]
      dr.records.first[:redcap_survey_identifier] = ''

      dr.summarize_fields
      dr.handle_survey_identifier
      expect { dr.store }.to raise_error(FphsException, /Integer survey identifier field is empty, can't set master id, for record 1/)

      expect(dr.updated_ids.length).to eq 0
      expect(dr.created_ids).to be_empty

      # Now try with a survey identifier that doesn't match any external ids
      dr.records.first[:redcap_survey_identifier] = -999

      dr.summarize_fields
      dr.handle_survey_identifier
      expect { dr.store }.to raise_error(FphsException, /Redcap pull failed to get master id through association, for record 1 with survey identifier -999/)

      expect(dr.updated_ids.length).to eq 0
      expect(dr.created_ids).to be_empty

      # Now check no error is raised if no survey identifier is provided when a default master is provided
      # Retrieving again makes the changes
      expect(Master.find(-1)).to be_a Master

      rc.data_options.skip_store_if_no_survey_identifier = -1
      rc.save!
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

      dr.retrieve
      dr.records.first[:redcap_survey_identifier] = ''

      dr.summarize_fields
      dr.handle_survey_identifier
      expect { dr.store }.not_to raise_error
      expect(dr.updated_ids.length).to eq 0
      expect(dr.skipped_ids.length).to eq 1
      expect(dr.created_ids).to be_empty

      get_rid = dr.skipped_ids.first[:record_id]
      expect(get_rid).to eq '1'
      res = dm.implementation_class.where(record_id: get_rid).reload
      expect(res.count).to eq 1
      expect(res.first.redcap_survey_identifier).to eq orig_rcsid
    end
  end
end
