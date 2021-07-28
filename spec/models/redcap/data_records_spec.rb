# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::DataRecords, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
    reset_mocks
  end

  it 'has a valid model to store records to, which must be a subclass of Dynamic::DynamicModelBase' do
    setup_file_fields
    dm = DynamicModel.active.where(category: 'redcap').first.implementation_class
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

    expect { dr.validate }.not_to raise_error
  end

  it 'raises errors if retrieved records id is missing' do
    dm = create_dynamic_model_for_sample_response

    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
    stub_request_records @project[:server_url], @project[:api_key], 'fail_record_id_nil'
    dr.retrieve
    expect { dr.validate }.to raise_error(FphsException, 'Redcap::DataRecords retrieved data that has a nil record id')
  end

  it 'raises errors if retrieved records have mismatched fields' do
    dm = create_dynamic_model_for_sample_response

    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    stub_request_records @project[:server_url], @project[:api_key], 'mismatch_fields'
    dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
    dr.retrieve
    expect do
      dr.validate
    end.to raise_error(FphsException,
                       "Redcap::DataRecords retrieved record fields are not present in the model:\nmismatch_field")
  end

  it 'stores retrieved records' do
    dm = create_dynamic_model_for_sample_response

    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    stub_request_records @project[:server_url], @project[:api_key]
    dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to eq %w[1 4 14 19 32].sort
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
                                          "Redcap::DataRecords retrieved record fields are not present in the model:\n" \
                                          'redcap_survey_identifier q2_survey_timestamp test_timestamp'
  end

  it 'complains if records are missing' do
    dm = create_dynamic_model_for_sample_response

    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    stub_request_records @project[:server_url], @project[:api_key]
    dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to eq %w[1 4 14 19 32].sort
    expect(dr.updated_ids).to be_empty

    WebMock.reset!
    rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)
    rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

    stub_request_records @project[:server_url], @project[:api_key], 'missing_record'
    dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
    dr.retrieve
    expect do
      dr.validate
    end.to raise_error(FphsException, 'Redcap::DataRecords existing records were not in the retrieved records: 4')
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
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to eq %w[1 4 14 19 32].sort
    expect(dr.updated_ids).to be_empty

    dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
    dr.retrieve
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
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to eq %w[1 4 14 19 32].sort
    expect(dr.updated_ids).to be_empty

    WebMock.reset!
    rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)

    rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

    stub_request_records @project[:server_url], @project[:api_key], 'updated_records'

    dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
    dr.retrieve
    expect { dr.validate }.not_to raise_error
    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to be_empty
    expect(dr.updated_ids.sort).to eq %w[1 4 14 19].sort
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
    expect(cr.result['created_ids']).not_to be_empty
    expect(cr.result['updated_ids']).to be_empty
    expect(cr.result['unchanged_ids']).to be_empty
    expect(cr.result['errors']).to be_empty
  end

  it 'downloads files' do
    setup_file_fields
    rc = @project_admin
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary

    dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')

    expect(dr.send(:file_fields)).to eq %i[file1 signature]

    dr.retrieve
    expect(dr.records.length).to be > 0

    dr.send(:capture_files, dr.records[1])
    puts dr.errors if dr.errors.present?
    expect(dr.errors).not_to be_present

    files = dr.imported_files
    expect(files.count).to eq 2
    expect(files.map { |f| "#{f.path}/#{f.file_name}" }.sort).to eq ["#{rc.dynamic_model_table}/file-fields/4/file1", "#{rc.dynamic_model_table}/file-fields/4/signature"]

    # Repeat - should not update the files
    dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
    dr.retrieve
    dr.send(:capture_files, dr.records[1])
    expect(dr.errors).not_to be_present
    files = dr.imported_files
    expect(files.count).to eq 0

    # Reset with new file content
    mock_file_field_requests
    dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')
    dr.retrieve
    dr.send(:capture_files, dr.records[1])
    expect(dr.errors).not_to be_present
    files = dr.imported_files
    expect(files.count).to eq 2
  end

  it 'downloads files in background' do
    setup_file_fields
    rc = @project_admin
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary

    dr = Redcap::DataRecords.new(rc, 'TestFileFieldRec')

    dm = DynamicModel.active.where(name: 'test_file_field_rec').first
    expect(dm).to be_a DynamicModel

    expect(dr.existing_records_length).to eq 0
    dr.request_records
    expect(dr.existing_records_length).to be > 0

    puts dr.errors if dr.errors.present?
    expect(dr.errors).not_to be_present

    files = rc.file_store.stored_files

    expect(files.count).to eq 4
    expect(files.map { |f| "#{f.path}/#{f.file_name}" }.sort)
      .to eq ["#{rc.dynamic_model_table}/file-fields/4/file1", "#{rc.dynamic_model_table}/file-fields/4/signature", "#{rc.dynamic_model_table}/file-fields/19/signature", "#{rc.dynamic_model_table}/file-fields/32/file1"].sort
  end
end
