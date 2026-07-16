# frozen_string_literal: true

# Tests for Redcap::ApiClient covering project, metadata, record, user and file
# retrieval from the REDCap API, including the #remove_project_user method
# added for issue #1259 (removing a user's access from a REDCap project) and
# its audit trail (Redcap::ClientRequest#result[:api_action]).
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

  it 'removes a user from the project' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    pc = rc.api_client

    stub_request_remove_project_user @project[:server_url], @project[:api_key], username: 'd20'

    res = pc.remove_project_user(username: 'd20')
    expect(pc.response_code).to eq 200
    expect(res).to eq 1

    audit = Redcap::ClientRequest.where(action: 'user').order(created_at: :desc).find { |cr| cr.result['api_action'] == 'delete' }
    expect(audit).to be_present
    expect(audit.action).to eq 'user'
    expect(audit.result['api_action']).to eq 'delete'

    # Removing a user does not automatically refresh (or invalidate) the
    # project_users cache - a subsequent call is still served fresh here only
    # because it wasn't cached yet in this example; a second call hits the cache.
    users = pc.project_users
    expect(pc.last_result_from_cache).to be false
    pc.project_users
    expect(pc.last_result_from_cache).to be true
    expect(users).to be_a Array
  end

  it 'force reloads the project_users cache on request' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    pc = rc.api_client

    pc.project_users
    expect(pc.last_result_from_cache).to be false
    pc.project_users
    expect(pc.last_result_from_cache).to be true

    users = pc.project_users(force_reload: true)
    expect(pc.last_result_from_cache).to be false
    expect(users).to be_a Array
  end

  it 'removes multiple users from the project using usernames' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    pc = rc.api_client

    stub_request_remove_project_user @project[:server_url], @project[:api_key], usernames: %w[d20 j86]

    res = pc.remove_project_user(usernames: %w[d20 j86])
    expect(pc.response_code).to eq 200
    expect(res).to eq 1
  end

  it 'requires a username to remove a project user' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    pc = rc.api_client

    expect do
      pc.remove_project_user
    end.to raise_error(FphsException, /requires a username/)
  end

  it 'imports a record' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    pc = rc.api_client

    data = [
      {'record_id' => 101, 'redcap_survey_identifier' => "651237"}
    ]

    json_data = data.to_json

    stub_requests_import_records @project[:server_url], @project[:api_key], data: json_data

    res = pc.import_records(data:)
    expect(res).to be_a Array
    expect(res.first).to be_a String
    expect(res[0]).to eq '101'

  end

  it 'gets a survey link for instrument and record' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    pc = rc.api_client

    instrument = 'test_api'
    record_id = 101

    stub_requests_survey_link @project[:server_url], @project[:api_key], instrument: instrument, record_id: record_id
    res = pc.survey_link(instrument:, record_id:)
    expect(res).to be_a String
    expect(res).to eq 'https://redcap.server/redcap/surveys/?s=nQpny44G2vwTMoeF'
  end
end
