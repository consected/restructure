# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::ProjectUsers, type: :model do
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

  it 'retrieves records from REDCap immediately' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    dr = Redcap::ProjectUsers.new(rc)

    res = dr.retrieve

    expect(res).to be_a Array
    expect(res.length).to eq 4
    expect(res.first).to be_a Hash
    expect(res.first.keys.first).to eq :username
  end

  it 'validates retrieved records' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    dr = Redcap::ProjectUsers.new(rc)

    dr.retrieve

    expect { dr.validate }.not_to raise_error
  end

  it 'stores retrieved records' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    dr = Redcap::ProjectUsers.new(rc)

    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to eq %w[d20 h16 j86 p106].sort
    expect(dr.updated_usernames).to be_empty
  end

  it 'does nothing if the records all match' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    dr = Redcap::ProjectUsers.new(rc)

    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to eq %w[d20 h16 j86 p106].sort
    expect(dr.updated_usernames).to be_empty

    dr = Redcap::ProjectUsers.new(rc)
    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to be_empty
    expect(dr.updated_usernames).to be_empty
  end

  it 'does updates on records that have changed' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    dr = Redcap::ProjectUsers.new(rc)

    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to eq %w[d20 h16 j86 p106].sort
    expect(dr.updated_usernames).to be_empty

    WebMock.reset!
    rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)

    rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

    stub_request_project_users_updated @project[:server_url], @project[:api_key]

    dr = Redcap::ProjectUsers.new(rc)
    dr.retrieve
    expect { dr.validate }.not_to raise_error
    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to be_empty
    expect(dr.updated_usernames.sort).to eq %w[h16 j86].sort
  end
end
