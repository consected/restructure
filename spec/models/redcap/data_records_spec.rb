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
    dm = DynamicModel.active.first.implementation_class
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
    rc.api_client.send :clear_cache, :records

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
    rc.api_client.send :clear_cache, :records

    stub_request_records @project[:server_url], @project[:api_key], 'updated_records'
    dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
    dr.retrieve
    expect { dr.validate }.not_to raise_error
    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to be_empty
    expect(dr.updated_ids.sort).to eq %w[14 19]
  end

  it 'retrieves all records in the background' do
    dm = create_dynamic_model_for_sample_response
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    start_time = DateTime.now
    dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

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
end
