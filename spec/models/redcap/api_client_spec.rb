# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::ApiClient, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
  end

  it 'connects and gets project info' do
    name = @projects.first[:name]

    rc = Redcap::ProjectAdmin.active.find_by_name(name)
    expect(rc).to be_a Redcap::ProjectAdmin

    rc.current_admin = @admin
    c = Redcap::ApiClient.new(rc)
    expect(c).to be_a Redcap::ApiClient
    expect(c.api_key).to eq rc.api_key
    expect(c.server_url).to eq rc.server_url
    expect(c.name).to eq rc.name

    expect(c.redcap).to be_a Redcap::Client

    m = c.project
    expect(m).to be_a Hash
    expect(m[:project_title]).to eq name
  end

  it 'requires a ProjectAdmin#current_admin to be set' do
    name = @projects.first[:name]

    rc = Redcap::ProjectAdmin.active.find_by_name(name)

    expect(rc).to be_a Redcap::ProjectAdmin

    expect do
      rc.api_client.metadata
    end.to raise_error(FphsException, 'Initialization with current_admin blank is not valid')
  end

  it 'connects and gets project data dictionary' do
    name = @projects.first[:name]

    rc = Redcap::ProjectAdmin.active.find_by_name(name)
    rc.current_admin = @admin
    expect(rc).to be_a Redcap::ProjectAdmin

    m = rc.api_client.metadata
    expect(m).to be_a Array
    expect(m).to be_present
  end

  it 'pulls all records from redcap' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    pc = rc.api_client

    res = pc.records
    expect(res).to be_a Array
    expect(res.first).to be_a Hash
    expect(res.first.keys).to be_present
    expect(res.first.keys.first).to be_a Symbol
    expect(res[1][:dob]).to eq '1998-04-16'
    expect(res[1][:record_id]).to eq '4'
  end

  it 'pulls all records from redcap with survey fields' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    pc = rc.api_client

    res = pc.records(request_options: { exportSurveyFields: true })
    expect(res).to be_a Array
    expect(res.first).to be_a Hash
    expect(res.first.keys).to be_present
    expect(res.first.keys.first).to be_a Symbol
    expect(res[1][:dob]).to eq '1998-04-16'
    expect(res[1][:record_id]).to eq '4'
    expect(res[1][:redcap_survey_identifier]).to be_a String
    expect(res[1][:q2_survey_timestamp]).to eq '[not completed]'
  end

  it 'pulls the project_xml file' do
    mock_file_field_requests
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    rc.server_url = server_url('file_field')
    pc = rc.api_client
    res = pc.project_archive
    expect(res).to be_a Tempfile
  end

  it 'pulls the users for the project' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    pc = rc.api_client

    res = pc.project_users
    expect(res).to be_a Array
    expect(res.first).to be_a Hash
    expect(res.first.keys).to be_present
    expect(res.first.keys.first).to be_a Symbol
    expect(res[0][:username]).to eq 'd20'
  end
end
