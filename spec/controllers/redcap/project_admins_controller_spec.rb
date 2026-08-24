# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::ProjectAdminsController, type: :controller do
  include UserSupport

  include MasterSupport
  include Redcap::RedcapSupport
  include Redcap::ProjectAdminSupport

  around do |example|
    if example.metadata[:queue_adapter_test]
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = original_adapter
    else
      example.run
    end
  end

  def object_class
    Redcap::ProjectAdmin
  end

  def item
    @project_admin
  end

  def edit_form_admin
    @edit_form_admin = 'admin/common_templates/_form'
  end

  # def saved_item_template
  #   'admin/common_templates/_item'
  # end

  before(:context) do
    @path_prefix = '/redcap'
    @admin, = ControllerMacros.create_admin
    create_admin_matching_user
  end

  before(:example) do
    create_admin_matching_user
  end

  it_behaves_like 'a standard admin controller'

  describe 'transfer mode "none" action restrictions' do
    before_each_login_admin

    before(:each) do
      setup_redcap_project_admin_configs
    end

    let!(:project_admin) do
      pa = Redcap::ProjectAdmin.active.first
      pa.current_admin = @admin
      pa.transfer_mode = 'none'
      pa.save!
      pa
    end

    it 'prevents request_latest_rc_configs action when transfer_mode is none' do
      post :request_latest_rc_configs, params: { id: project_admin.id }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Actions cannot be performed on projects with transfer mode "none"/)
    end

    it 'prevents request_records action when transfer_mode is none' do
      project_admin.update!(dynamic_model_table: 'test.test_tables')

      post :request_records, params: { id: project_admin.id }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Actions cannot be performed on projects with transfer mode "none"/)
    end

    it 'prevents request_archive action when transfer_mode is none' do
      post :request_archive, params: { id: project_admin.id }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Actions cannot be performed on projects with transfer mode "none"/)
    end

    it 'prevents request_archive_definition action when transfer_mode is none' do
      post :request_archive_definition, params: { id: project_admin.id }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Actions cannot be performed on projects with transfer mode "none"/)
    end

    it 'prevents request_users action when transfer_mode is none' do
      post :request_users, params: { id: project_admin.id }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Actions cannot be performed on projects with transfer mode "none"/)
    end

    it 'prevents request_data_collection_instruments action when transfer_mode is none' do
      post :request_data_collection_instruments, params: { id: project_admin.id }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Actions cannot be performed on projects with transfer mode "none"/)
    end

    it 'prevents request_logs action when transfer_mode is none' do
      post :request_logs, params: { id: project_admin.id }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Actions cannot be performed on projects with transfer mode "none"/)
    end

    it 'prevents force_reconfig action when transfer_mode is none' do
      post :force_reconfig, params: { id: project_admin.id }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Actions cannot be performed on projects with transfer mode "none"/)
    end

    it 'prevents update_dynamic_model action when transfer_mode is none' do
      post :update_dynamic_model, params: { id: project_admin.id }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Actions cannot be performed on projects with transfer mode "none"/)
    end

    it 'prevents remove_user action when transfer_mode is none' do
      post :remove_user, params: { id: project_admin.id, username: 'd20' }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Actions cannot be performed on projects with transfer mode "none"/)
    end

    it 'allows actions when transfer_mode is "scheduled"' do
      project_admin.update!(transfer_mode: 'scheduled')

      expect do
        post :request_users, params: { id: project_admin.id }, format: :json
      end.not_to raise_error

      expect(response).to have_http_status(200)
    end

    it 'allows actions when transfer_mode is "manual"' do
      project_admin.update!(transfer_mode: 'manual')

      expect do
        post :request_users, params: { id: project_admin.id }, format: :json
      end.not_to raise_error

      expect(response).to have_http_status(200)
    end

    it 'queues a definition-only archive when transfer_mode is enabled', queue_adapter_test: true do
      project_admin.update!(transfer_mode: 'manual')

      expect do
        post :request_archive_definition, params: { id: project_admin.id }, format: :json
      end.to have_enqueued_job(Redcap::CaptureProjectArchiveJob).with(project_admin, definition_only: true)

      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['message']).to match(/Project definition requested/)
    end
  end

  describe 'remove_user action' do
    before_each_login_admin

    before(:each) do
      setup_redcap_project_admin_configs
    end

    let!(:project_admin) do
      pa = Redcap::ProjectAdmin.active.first
      pa.current_admin = @admin
      pa.transfer_mode = 'manual'
      pa.save!
      pa
    end

    it 'requires a username parameter' do
      post :remove_user, params: { id: project_admin.id }, format: :json
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/username is required/)
    end

    it 'enqueues a job to remove the user and returns a success message' do
      fake_job = double('job', job_id: 'test-job-id')
      allow(Redcap::RemoveProjectUserJob).to receive(:perform_later).and_return(fake_job)

      expect do
        post :remove_user, params: { id: project_admin.id, username: 'd20' }, format: :json
      end.not_to raise_error

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to match(/Removal of user d20 requested/)
      expect(Redcap::RemoveProjectUserJob).to have_received(:perform_later).with(project_admin, 'd20')
    end
  end
end
