# frozen_string_literal: true

# Tests for GitHub issue #1403: "Provide an endpoint for Redcap 'Data Entry
# Trigger' requests".
#
# Covers Redcap::ProjectUserRequestsController#data_entry_trigger, which allows
# a REDCap project's Data Entry Trigger to call directly into this application
# (instead of via a separate infrastructure stopgap), requesting the matching
# project's records be pulled whenever a record/survey response changes.
#
# Covers:
#   - The endpoint is effectively disabled (404) if the ref-data app type is not
#     active on this server
#   - A user without redcap_pull_request access is rejected
#   - A user without access to the ref-data app_type itself is rejected, even with
#     redcap_pull_request access
#   - An unmatched project_id/redcap_url is rejected
#   - An invalid internal_project_token is rejected
#   - A GET request (REDCap's "Test" button) validates the request but never
#     triggers a pull, and succeeds using only the params in the generated
#     data_entry_trigger_url (no project_id/redcap_url, which REDCap only ever
#     sends in its own POST payload)
#   - A valid POST request triggers a records request for the matching project
#   - A POST request for a project with no dynamic model configured is rejected

require 'rails_helper'

RSpec.describe Redcap::ProjectUserRequestsController, type: :controller do
  include UserSupport
  include MasterSupport
  include Redcap::RedcapSupport
  include Redcap::ProjectAdminSupport

  before(:context) do
    @admin, = ControllerMacros.create_admin
    create_admin_matching_user
  end

  before(:example) do
    create_admin_matching_user
    setup_access :redcap_pull_request, resource_type: :general, access: :read, user: @user
    # setup_redcap_project_admin_configs (below) reassigns @user/@admin to REDCap job admin/user
    # as a side effect, so remember the actually signed-in, authorized user separately.
    @authorized_user = @user
    @request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in @user
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
      project_id: captured_project_id.to_s,
      redcap_url: @project_admin.server_url,
      internal_project_token: @valid_token
    }.merge(overrides)
  end

  describe 'when the ref-data app type is not active on this server' do
    it 'returns 404 (effectively disabled)' do
      allow_any_instance_of(Admin::AppType).to receive(:active_on_server?).and_return(false)

      get :data_entry_trigger, params: valid_params, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'authorization' do
    it 'rejects a user without redcap_pull_request access' do
      Admin::UserAccessControl.where(user: @authorized_user, resource_name: 'redcap_pull_request').find_each do |uac|
        uac.current_admin = auto_admin
        uac.update!(disabled: true)
      end
      @authorized_user.clear_role_names!

      get :data_entry_trigger, params: valid_params, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'accepts a user granted redcap_pull_request access' do
      get :data_entry_trigger, params: valid_params, format: :json

      expect(response).to have_http_status(:ok)
    end

    it 'rejects a user granted redcap_pull_request access but not access to the ref-data app_type itself' do
      # A per-user UAC disable alone isn't reliable here: this server's ref-data app type has a
      # default (non-user-specific) app_type access grant that a disabled per-user override falls
      # back to (see Admin::UserAccessControl.evaluate_access_for/scope_user_and_role). Stub the
      # specific check instead, to directly verify the controller enforces it.
      allow_any_instance_of(User).to receive(:can?).and_call_original
      allow_any_instance_of(User).to receive(:can?).with(:app_type).and_return(false)

      get :data_entry_trigger, params: valid_params, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'project lookup' do
    it 'rejects a request when no project matches the project_id/redcap_url' do
      get :data_entry_trigger, params: valid_params(project_id: '999999'), format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to match(/no matching project/i)
    end

    it 'tolerates a redcap_url whose path differs from the stored server_url' do
      uri = URI.parse(@project_admin.server_url)
      alt_url = "#{uri.scheme}://#{uri.host}/different/path/"

      get :data_entry_trigger, params: valid_params(redcap_url: alt_url), format: :json

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'internal_project_token validation' do
    it 'rejects an invalid internal_project_token' do
      get :data_entry_trigger, params: valid_params(internal_project_token: 'wrong-token'), format: :json

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['message']).to match(/internal_project_token/i)
    end

    it 'rejects a missing internal_project_token' do
      get :data_entry_trigger, params: valid_params(internal_project_token: nil), format: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET request (REDCap "Test" button)' do
    it 'validates the request and returns OK without triggering a pull' do
      expect_any_instance_of(Redcap::ProjectAdmin).not_to receive(:dynamic_storage)

      get :data_entry_trigger, params: valid_params, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('OK')
    end
  end

  describe 'generated data_entry_trigger_url' do
    it 'contains only user_email, user_token and internal_project_token params' do
      uri = URI.parse(@project_admin.data_entry_trigger_url)

      expect(uri.path).to eq '/redcap/project_user_requests/data_entry_trigger.json'
      query_keys = Rack::Utils.parse_nested_query(uri.query).keys
      expect(query_keys).to match_array(%w[user_email user_token internal_project_token])
    end

    it 'succeeds via a real GET using only those params, with no project_id/redcap_url' do
      get :data_entry_trigger, params: {
        user_email: @authorized_user.email,
        user_token: @authorized_user.authentication_token,
        internal_project_token: @valid_token
      }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('OK')
    end
  end

  describe 'POST request' do
    it 'rejects the request when the project has no dynamic model table configured' do
      expect(@project_admin.dynamic_model_table).to be_blank

      post :data_entry_trigger, params: valid_params, format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to match(/not ready/i)
    end

    it 'triggers a records request for the matching project when it is ready' do
      allow_any_instance_of(Redcap::ProjectAdmin).to receive(:dynamic_model_table).and_return('some_table')
      allow_any_instance_of(Redcap::ProjectAdmin).to receive(:dynamic_model_ready?).and_return(true)
      fake_storage = instance_double(Redcap::DynamicStorage)
      allow_any_instance_of(Redcap::ProjectAdmin).to receive(:dynamic_storage).and_return(fake_storage)
      expect(fake_storage).to receive(:request_records).with(request_source: :api)

      post :data_entry_trigger, params: valid_params, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to include('Records requested')
    end
  end
end
