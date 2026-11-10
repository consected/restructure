# frozen_string_literal: true

# Full-stack (type: :request) coverage for the REDCap Data Entry Trigger endpoint,
# exercising the REAL token-based API authentication path (user_email/user_token
# query params, no browser session/CSRF token) that REDCap itself uses when it
# calls this endpoint - as opposed to
# spec/controllers/redcap/data_entry_trigger_controller_spec.rb, which uses
# Devise's `sign_in` test helper and so never exercises Warden/
# simple_token_authentication or CSRF handling.
#
# Covers:
#   - A real GET request (REDCap's "Test" button) authenticates via user_email/
#     user_token alone and returns 200 OK
#   - An invalid user_token is rejected
#   - An unknown user_email is rejected
#   - A real POST request authenticates and triggers a records request

require 'rails_helper'

RSpec.describe 'REDCap Data Entry Trigger endpoint (API token auth)', type: :request do
  include UserSupport
  include MasterSupport
  include Redcap::RedcapSupport
  include Redcap::ProjectAdminSupport

  before(:all) do
    @admin, = ControllerMacros.create_admin
    create_admin_matching_user
  end

  before(:each) do
    create_admin_matching_user
    setup_access :redcap_pull_request, resource_type: :general, access: :read, user: @user
    # setup_redcap_project_admin_configs (below) reassigns @user/@admin to REDCap job admin/user
    # as a side effect, so remember the actually authorized user separately.
    @authorized_user = @user
    @user_token = @authorized_user.authentication_token
    expect(@user_token).to be_present
  end

  let(:captured_project_id) { 88_888 }

  before(:each) do
    setup_redcap_project_admin_configs
    @project_admin = Redcap::ProjectAdmin.active.first
    @project_admin.update_columns(captured_project_info: { 'project_id' => captured_project_id })
    @valid_token = @project_admin.internal_project_token
    allow_any_instance_of(Redcap::ProjectAdmin).to receive(:capture_project_users)
  end

  def valid_params(overrides = {})
    {
      user_email: @authorized_user.email,
      user_token: @user_token,
      project_id: captured_project_id.to_s,
      redcap_url: @project_admin.server_url,
      internal_project_token: @valid_token
    }.merge(overrides)
  end

  it 'authenticates and responds OK to a real GET request using only user_email/user_token params' do
    get '/redcap/project_user_requests/data_entry_trigger.json', params: valid_params

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['message']).to eq('OK')
  end

  it 'succeeds by calling the generated data_entry_trigger_url verbatim, substituting only the placeholder user credentials' do
    uri = URI.parse(@project_admin.data_entry_trigger_url)
    query = Rack::Utils.parse_nested_query(uri.query)

    # An admin pastes this URL into REDCap after substituting the placeholder user_token with a
    # real one (and, in this test, the placeholder user_email with our test user's real email) -
    # REDCap's "Test" button then calls it exactly as configured, with no other params.
    query['user_email'] = @authorized_user.email
    query['user_token'] = @user_token

    get uri.path, params: query

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['message']).to eq('OK')
  end

  it 'rejects the request when user_token is invalid' do
    get '/redcap/project_user_requests/data_entry_trigger.json', params: valid_params(user_token: 'wrong-token')

    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects the request when user_email is unknown' do
    get '/redcap/project_user_requests/data_entry_trigger.json', params: valid_params(user_email: 'nobody@example.com')

    expect(response).to have_http_status(:unauthorized)
  end

  it 'authenticates and triggers a records request for a real POST request' do
    allow_any_instance_of(Redcap::ProjectAdmin).to receive(:dynamic_model_table).and_return('some_table')
    allow_any_instance_of(Redcap::ProjectAdmin).to receive(:dynamic_model_ready?).and_return(true)
    fake_storage = instance_double(Redcap::DynamicStorage)
    allow_any_instance_of(Redcap::ProjectAdmin).to receive(:dynamic_storage).and_return(fake_storage)
    expect(fake_storage).to receive(:request_records).with(request_source: :api)

    post '/redcap/project_user_requests/data_entry_trigger.json', params: valid_params

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['message']).to include('Records requested')
  end
end
