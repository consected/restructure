# frozen_string_literal: true

# Specs for Redcap::ProjectUserRequestsController
# Focused on the set_instance_from_id private method, which looks up a REDCap
# project admin by integer ID, project_id+server_url, or project_name.
#
# Tests cover (issue #1116):
#   - Exact server_url match when looking up by project_id
#   - Lenient fallback to protocol+host match when server_url paths differ
#   - Hostname prefix collisions do not match (e.g. redcap.partners.org vs redcap.partners.org.evil)
#   - Hostless but parseable URLs do not match all https projects
#   - No match raises FphsException with project_id and server_url in message
#   - Malformed server_url param does not cause a 500 error
#   - project_name lookup failure includes project_name (not project_id/server_url) in message

require 'rails_helper'

RSpec.describe Redcap::ProjectUserRequestsController, type: :controller do
  include UserSupport
  include MasterSupport
  include Redcap::RedcapSupport
  include Redcap::ProjectAdminSupport

  before(:context) do
    @path_prefix = '/redcap'
    @admin, = ControllerMacros.create_admin
    create_admin_matching_user
  end

  before(:example) do
    create_admin_matching_user
    setup_access :redcap_pull_request, resource_type: :general, access: :read, user: @user
    @request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in @user
  end

  let(:captured_project_id) { 88_888 }

  describe 'set_instance_from_id with project_id' do
    before(:each) do
      setup_redcap_project_admin_configs
      @project_admin = Redcap::ProjectAdmin.active.first
      @project_admin.update_columns(captured_project_info: { 'project_id' => captured_project_id })
      # Stub the downstream REDCap API call so the action can complete
      allow_any_instance_of(Redcap::ProjectAdmin).to receive(:capture_project_users)
    end

    it 'finds the project via exact server_url match' do
      post :request_users,
           params: {
             id: 'project_id',
             project_id: captured_project_id.to_s,
             server_url: @project_admin.server_url
           },
           format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to include('Project users requested')
    end

    it 'finds the project via lenient matching when server_url path differs' do
      uri = URI.parse(@project_admin.server_url)
      alt_url = "#{uri.scheme}://#{uri.host}/different/path/"

      post :request_users,
           params: {
             id: 'project_id',
             project_id: captured_project_id.to_s,
             server_url: alt_url
           },
           format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to include('Project users requested')
    end

    it 'does not match when only a hostname prefix matches' do
      uri = URI.parse(@project_admin.server_url)
      @project_admin.update_columns(server_url: "#{uri.scheme}://#{uri.host}.evil/redcap/api/")

      post :request_users,
           params: {
             id: 'project_id',
             project_id: captured_project_id.to_s,
             server_url: "#{uri.scheme}://#{uri.host}/different/path/"
           },
           format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include("project_id: #{captured_project_id}")
    end

    it 'does not match when the server_url is parseable but hostless' do
      post :request_users,
           params: {
             id: 'project_id',
             project_id: captured_project_id.to_s,
             server_url: 'https:///foo'
           },
           format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('no matching project found')
    end

    it 'returns 400 with project_id and server_url in message when no project matches' do
      post :request_users,
           params: {
             id: 'project_id',
             project_id: captured_project_id.to_s,
             server_url: 'https://no-match.example.com/api/'
           },
           format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include("project_id: #{captured_project_id}")
      expect(json['message']).to include('server_url: https://no-match.example.com/api/')
    end

    it 'returns 400 (not 500) when server_url is malformed' do
      post :request_users,
           params: {
             id: 'project_id',
             project_id: captured_project_id.to_s,
             server_url: 'not a valid url %%'
           },
           format: :json

      expect(response).not_to have_http_status(:internal_server_error)
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('no matching project found')
    end
  end

  describe 'set_instance_from_id with project_name' do
    before(:each) do
      setup_redcap_project_admin_configs
      allow_any_instance_of(Redcap::ProjectAdmin).to receive(:capture_project_users)
    end

    it 'includes project_name in error message when not found, without project_id or server_url' do
      post :request_users,
           params: {
             id: 'project_name',
             project_name: 'nonexistent_project_xyz'
           },
           format: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['message']).to include('project_name: nonexistent_project_xyz')
      expect(json['message']).not_to match(/\bproject_id:/)
      expect(json['message']).not_to match(/\bserver_url:/)
    end
  end
end
