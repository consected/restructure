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
      expect(cr.result['count_created_ids']).to be > 0
      expect(cr.result['count_updated_ids']).to eq 0
      expect(cr.result['count_unchanged_ids']).to eq 0
      expect(cr.result['errors']).to be_empty
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

      cr = Redcap::ClientRequest.where(admin: request_admin,
                                       action: 'store records',
                                       server_url: rc.server_url,
                                       name: rc.name,
                                       redcap_project_admin: rc)
                                .where('created_at > :created_at', created_at: start_time)
                                .last

      expect(cr.result).to be_a Hash
      expect(cr.result['count_created_ids']).to be > 0
      expect(cr.result['count_updated_ids']).to eq 0
      expect(cr.result['count_unchanged_ids']).to eq 0
      expect(cr.result['errors']).to be_empty
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

      cr = Redcap::ClientRequest.where(admin: request_admin,
                                       action: 'store records',
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

      cr = Redcap::ClientRequest.where(admin: request_admin,
                                       action: 'store records',
                                       server_url: rc.server_url,
                                       name: rc.name,
                                       redcap_project_admin: rc)
                                .where('created_at > :created_at', created_at: start_time)
                                .last

      expect(cr.result['storage_stage']).to eq 'validate'

      cr = Redcap::ClientRequest.where(admin: request_admin,
                                       action: 'capture records job',
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

      dd = rc.redcap_data_dictionary
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
      dd = rc.redcap_data_dictionary

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
        exp_array = %w[pnfl dnfl anfl].map { |choice| r["smoketime___#{choice}"] && choice }.select { |item| item }

        expect(sa).to eq exp_array
      end
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
