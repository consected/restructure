# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::DataRecords, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :all do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
    reset_mocks

    server_url = @project[:server_url] + '?v=getfull'

    stub_request_full_project server_url, @project[:api_key]
    stub_request_full_metadata server_url, @project[:api_key]
    stub_request_full_records server_url, @project[:api_key]

    `mkdir -p db/app_migrations/redcap_test; rm -f db/app_migrations/redcap_test/*test_full_rc*.rb`

    tn = "redcap_test.test_full_rc#{rand 100_000_000_000_000}_recs"
    @project_admin = rc = Redcap::ProjectAdmin.create! name: @project[:name], server_url: server_url, api_key: @project[:api_key], study: 'Q3',
                                                       current_admin: @admin, dynamic_model_table: tn

    @dm = rc.dynamic_storage.dynamic_model
    expect(rc.dynamic_storage.dynamic_model_ready?).to be_truthy
    @dmcn = @dm.implementation_class.name
  end

  it 'cleanly handles full records' do
    rc = @project_admin
    rc.current_admin = @admin
    reset_mocks

    dr = Redcap::DataRecords.new(rc, @dmcn)
    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to eq (1..33).map(&:to_s).sort
    expect(dr.updated_ids).to be_empty

    dr = Redcap::DataRecords.new(rc, @dmcn)
    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to be_empty
    expect(dr.updated_ids).to be_empty
  end
end
