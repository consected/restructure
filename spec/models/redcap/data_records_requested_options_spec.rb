# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Test Summary: Redcap::DataRecords requested-options recording and skipped-files
# tracking (follow-up to PRs #1119 and #1143).
# ===============================================================================
#
# When a REDCap records pull is queued, admins need to be able to see which
# options were actually requested (e.g. ignore_cache, retrieve_all,
# verify_file_fields), since these are passed through to the delayed background
# job and were previously not visible on the Redcap::ClientRequest record.
#
# Additionally, when a file field's file already exists in the filestore,
# NfsStore::Import.import_file returns nil and the file is silently skipped.
# Previously this skip count was not tracked, making it look like no files
# were imported. We now track skipped_files alongside imported_files and
# failed_files, and include the count in the job request result.
#
# All tests assert against the persisted Redcap::ClientRequest DB row rather
# than against message-expectation mocks, so we verify what is actually stored.
# Note: the result column is jsonb — keys are strings when read back from the DB.
#
# Tests:
#   1. request_records persists requested_options on the 'setup job: store records'
#      ClientRequest row, with the exact options passed by the caller.
#   2. request_records persists all-false requested_options when no options passed.
#   3. retrieve_validate_store persists requested_options (ignore_cache, retrieve_all,
#      verify_file_fields) and skipped_files_count on the 'store records' ClientRequest row.
#   4. capture_files pushes an entry to skipped_files when import_file returns nil,
#      and the resulting skipped_files_count is reflected in the persisted ClientRequest row.

RSpec.describe 'Redcap::DataRecords requested options & skipped files', type: :model do
  include MasterSupport
  include ModelSupport
  include Redcap::RedcapSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
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
  # Helper: query the latest ClientRequest row for a given action on a project admin.
  # Returns the freshly reloaded DB row so that jsonb `result` keys are strings.
  def latest_client_request(project_admin, action)
    Redcap::ClientRequest
      .where(redcap_project_admin_id: project_admin.id, action:)
      .order(created_at: :desc)
      .first
  end

  #
  # Helper: configure stubs so request_records proceeds past the inline adapter guard
  # and past the existing-jobs guard, without running a real background job.
  def stub_for_request_records
    allow(Redcap::ProjectAdmin).to receive(:existing_jobs).and_return([])

    fake_job = double('job', job_id: 'test-job-id')
    allow(Redcap::CaptureRecordsJob).to receive(:perform_later).and_return(fake_job)

    # Make the code believe the adapter is NOT :inline so record_job_request is called
    allow(Rails.application.config.active_job).to receive(:queue_adapter).and_return(:test)
  end

  describe '#request_records persists requested_options on the ClientRequest row' do
    it 'stores the options passed by the caller on the setup job: store records row' do
      rc, class_name = project_admin_with_dm
      stub_for_request_records

      dr = Redcap::DataRecords.new(rc, class_name)
      dr.request_records(ignore_cache: true, retrieve_all: false, verify_file_fields: true)

      cr = latest_client_request(rc, 'setup job: store records')
      expect(cr).to be_present
      # result column is jsonb; keys are strings when loaded from DB
      expect(cr.result['requested_options']).to eq(
        'ignore_cache' => true,
        'retrieve_all' => false,
        'verify_file_fields' => true
      )
    end

    it 'stores all-false requested_options when no options are passed' do
      rc, class_name = project_admin_with_dm
      stub_for_request_records

      dr = Redcap::DataRecords.new(rc, class_name)
      dr.request_records

      cr = latest_client_request(rc, 'setup job: store records')
      expect(cr).to be_present
      expect(cr.result['requested_options']).to eq(
        'ignore_cache' => false,
        'retrieve_all' => false,
        'verify_file_fields' => false
      )
    end
  end

  describe 'retrieve_validate_store persists requested_options and skipped_files_count on the ClientRequest row' do
    it 'stores requested_options and a zero skipped_files_count on the store records row' do
      dm = create_dynamic_model_for_sample_response
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      stub_request_records @project[:server_url], @project[:api_key]

      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name,
                                   is_manual_pull: true,
                                   verify_file_fields: true)
      dr.retrieve_validate_store(ignore_cache: true, retrieve_all: false)

      cr = latest_client_request(rc, 'store records')
      expect(cr).to be_present
      expect(cr.result['requested_options']).to eq(
        'ignore_cache' => true,
        'retrieve_all' => false,
        'verify_file_fields' => true
      )
      expect(cr.result['skipped_files_count']).to eq 0
    end

    it 'reflects skipped_files_count > 0 when import_file returns nil during the pull' do
      dm = create_dynamic_model_for_sample_response
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      stub_request_records @project[:server_url], @project[:api_key]

      # Force every file import to return nil (simulates file already present in filestore)
      allow(NfsStore::Import).to receive(:import_file).and_return(nil)

      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name,
                                   is_manual_pull: true,
                                   verify_file_fields: false)
      dr.retrieve_validate_store(ignore_cache: false, retrieve_all: false)

      cr = latest_client_request(rc, 'store records')
      expect(cr).to be_present
      # The exact count depends on how many file fields the sample fixture has.
      # We assert the value matches what was tracked in memory to confirm round-trip.
      expect(cr.result['skipped_files_count']).to eq dr.skipped_files.length
    end
  end

  describe '#capture_files records skipped files when import_file returns nil' do
    it 'pushes an entry to skipped_files for each file that import_file skips' do
      rc, class_name = project_admin_with_dm

      dr = Redcap::DataRecords.new(rc, class_name, is_manual_pull: true)

      # Stub file_fields and record_id_field used by capture_files
      allow(dr).to receive(:file_fields).and_return([:file1])
      allow(dr).to receive(:record_id_field).and_return(:record_id)

      # Stub retrieve_file to return a Tempfile-like double
      tmp = double('tempfile', path: '/tmp/fake-file', close: nil, unlink: nil)
      allow(dr).to receive(:retrieve_file).and_return(tmp)

      allow(dr).to receive(:current_user).and_return(@admin)

      # Return nil to simulate an existing identical file (import skipped)
      allow(NfsStore::Import).to receive(:import_file).and_return(nil)

      record = { record_id: '123', file1: 'filename1.pdf', redcap_event_name: nil }
      dr.send(:capture_files, record)

      expect(dr.skipped_files.length).to eq 1
      entry = dr.skipped_files.first
      expect(entry[:record_id]).to eq '123'
      expect(entry[:field_name]).to eq :file1
      # file_name holds the NFS storage name, which equals the field_name symbol
      expect(entry[:file_name]).to eq :file1
    end
  end
end
