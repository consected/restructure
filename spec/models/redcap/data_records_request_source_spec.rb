# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Test Summary: Redcap::DataRecords request source recording (GitHub issue #1118)
# ===============================================================================
#
# A REDCap project `request_records` call may originate from:
#   - The admin UI (ProjectAdminsController)
#   - An API call (ProjectUserRequestsController)
#   - An automated scheduled job (RecurringPullTask)
#
# These tests verify that the source of the request is captured in the
# project admin job request result, so admins can tell how a pull was triggered.
#
# The implementation adds a `request_source` attribute to Redcap::DataRecords
# (values: :admin_ui, :api, :scheduled, or nil) and threads the value through to
# the relevant `record_job_request` / `update_job_request` calls.
#
# Tests:
#   1. request_records with request_source: :admin_ui records admin_ui: true in
#      the 'setup job: store records' job request result.
#   2. request_records with request_source: :api records api: true in the
#      'setup job: store records' job request result.
#   3. request_records with no request_source does NOT include admin_ui: true
#      or api: true in the job request result.
#   4. When request_source: :scheduled is set on a DataRecords instance,
#      retrieve_validate_store records scheduled: true in the
#      'store records' job request result.

RSpec.describe 'Redcap::DataRecords request source recording', type: :model do
  include MasterSupport
  include ModelSupport
  include Redcap::RedcapSupport

  before :all do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
  end

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    change_setting('RedcapJobUserEmail', @admin.email)
    setup_file_store
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
    reset_mocks
  end

  #
  # Helper: return a ProjectAdmin with current_admin set and a valid dynamic model class_name
  def project_admin_with_dm
    dm = create_dynamic_model_for_sample_response
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    [rc, dm.implementation_class.name]
  end

  #
  # Helper: configure stubs so request_records proceeds past the inline adapter guard
  # and past the existing-jobs guard, without running a real background job.
  def stub_for_request_records(rc)
    # Prevent the "already queued" early return
    allow(Redcap::ProjectAdmin).to receive(:existing_jobs).and_return(double(count: 0))

    # Prevent the real job from running
    fake_job = double('job', job_id: 'test-job-id')
    allow(Redcap::CaptureRecordsJob).to receive(:perform_later).and_return(fake_job)

    # Make the code believe the adapter is NOT inline so it continues to record_job_request
    allow(Rails.application.config.active_job).to receive(:queue_adapter).and_return(:test)
  end

  describe 'request_records with request_source: :admin_ui' do
    it 'records admin_ui: true in the setup job: store records job request result' do
      rc, class_name = project_admin_with_dm
      stub_for_request_records(rc)

      # Expect the job request to include admin_ui: true in the result
      expect(rc).to receive(:record_job_request).with(
        'setup job: store records',
        result: hash_including(admin_ui: true)
      )

      dr = Redcap::DataRecords.new(rc, class_name, request_source: :admin_ui)
      dr.request_records
    end
  end

  describe 'request_records with request_source: :api' do
    it 'records api: true in the setup job: store records job request result' do
      rc, class_name = project_admin_with_dm
      stub_for_request_records(rc)

      expect(rc).to receive(:record_job_request).with(
        'setup job: store records',
        result: hash_including(api: true)
      )

      dr = Redcap::DataRecords.new(rc, class_name, request_source: :api)
      dr.request_records
    end
  end

  describe 'request_records with no request_source' do
    it 'does not include admin_ui: true or api: true in the job request result' do
      rc, class_name = project_admin_with_dm
      stub_for_request_records(rc)

      expect(rc).to receive(:record_job_request) do |action, result:|
        expect(action).to eq 'setup job: store records'
        expect(result).not_to include(admin_ui: true)
        expect(result).not_to include(api: true)
      end

      dr = Redcap::DataRecords.new(rc, class_name)
      dr.request_records
    end
  end

  describe 'retrieve_validate_store with request_source: :scheduled' do
    it 'records scheduled: true in the store records job request result' do
      dm = create_dynamic_model_for_sample_response
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      stub_request_records @project[:server_url], @project[:api_key]

      # Allow any other record_job_request calls (e.g., api_client initialization calls :project)
      allow(rc).to receive(:record_job_request).and_call_original
      # Capture what record_job_request is called with when create: true
      expect(rc).to receive(:record_job_request).with(
        'store records',
        result: hash_including(scheduled: true)
      ).and_call_original

      # Allow any subsequent update_job_request calls (e.g., during store steps)
      allow(rc).to receive(:update_job_request)

      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name, request_source: :scheduled)
      dr.retrieve_validate_store
    end
  end
end
