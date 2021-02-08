# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::ProjectAdmin, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
  end

  it 'requires an admin' do
    expect do
      Redcap::ProjectAdmin.create! current_admin: nil, name: 'test', api_key: 'abc', server_url: 'https://testapi'
    end
      .to raise_error('Current admin not set')

    expect do
      Redcap::ProjectAdmin.create! current_admin: @bad_admin, name: 'test', api_key: 'abc', server_url: 'https://testapi'
    end
      .to raise_error('Admin not enabled')
  end

  it 'has a name that cannot be duplicated' do
    name = @projects.first[:name]
    expect(name).to be_present

    expect(Redcap::ProjectAdmin.active.find_by_name(name)).not_to be_nil

    res = Redcap::ProjectAdmin.new current_admin: @admin, name: name, api_key: 'abc', server_url: 'https://testapi'
    expect(res.save).to eq false
    expect(res.errors).to include :name
  end

  it 'has a name, api_key and server_url that must be present' do
    res = Redcap::ProjectAdmin.new current_admin: @admin, name: nil, api_key: nil, server_url: nil
    expect(res.save).to eq false
    expect(res.errors).to include :name
    expect(res.errors).to include :api_key
    expect(res.errors).to include :server_url
  end

  it 'encrypts the api_key in the database' do
    Redcap::ProjectAdmin.update_all(disabled: true)

    p = @projects.first
    rc = Redcap::ProjectAdmin.create! current_admin: @admin,
                                      name: p[:name],
                                      api_key: p[:api_key],
                                      server_url: p[:server_url]

    expect(rc.api_key).to eq p[:api_key]

    expect(rc.attributes['api_key']).not_to eq p[:api_key]
  end

  it 'empties the api_key when a record is disabled' do
    rc = Redcap::ProjectAdmin.active.first
    expect(rc.api_key).to be_present

    res = rc.update(current_admin: @admin, disabled: true)
    expect(res).to be true

    # Force a reload
    rc = Redcap::ProjectAdmin.find(rc.id)
    expect(rc.api_key).to be_nil
  end

  it 'gets the project info for display' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    pi = rc.captured_project_info
    expect(pi).to be_a Hash
    expect(pi[:project_title]).to eq rc[:name]
  end

  # NOTE: captured project info is handled within a job, so in reality will not return immediately
  it 'stores the project info for future reference' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    expect(rc.captured_project_info).to eq rc.project_client.project
  end
end
