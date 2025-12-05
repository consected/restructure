# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::ProjectAdmin, type: :model do
  include UserSupport
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
  end

  it 'requires an admin' do
    expect do
      Redcap::ProjectAdmin.create! current_admin: nil, name: 'test', api_key: 'abc', server_url: @project[:server_url],
                                   study: 'Q2 Demo'
    end
      .to raise_error('Current admin not set')

    expect do
      Redcap::ProjectAdmin.create! current_admin: @bad_admin, name: 'test', api_key: 'abc',
                                   server_url: @project[:server_url], study: 'Q2 Demo'
    end
      .to raise_error('Admin not enabled')
  end

  it 'has a name that cannot be duplicated within a study' do
    name = @projects.first[:name]
    expect(name).to be_present

    expect(Redcap::ProjectAdmin.active.where(name:, study: 'Q2').first).not_to be_nil

    res = Redcap::ProjectAdmin.new current_admin: @admin, name:, api_key: 'abc', server_url: @project[:server_url],
                                   study: 'Q2'
    expect(res.save).to eq false
    expect(res.errors).to include :name
  end

  it 'has a study, name, api_key and server_url that must be present' do
    res = Redcap::ProjectAdmin.new current_admin: @admin, name: nil, api_key: nil, server_url: nil, study: nil
    expect(res.save).to eq false
    expect(res.errors).to include :study
    expect(res.errors).to include :name
    # expect(res.errors).to include :api_key
    expect(res.errors).to include :server_url
  end

  it 'encrypts the api_key in the database' do
    Redcap::ProjectAdmin.update_all(disabled: true)

    p = @projects.first
    rc = Redcap::ProjectAdmin.create! current_admin: @admin,
                                      name: p[:name],
                                      api_key: p[:api_key],
                                      server_url: p[:server_url],
                                      study: 'Q2 Demo'

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
    expect(rc.captured_project_info).to eq rc.api_client.project
  end

  it 'creates a filestore container for file fields and project XML dump' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    expect(@user.app_type_id).not_to be_nil
    expect(rc.file_store).to be_a NfsStore::Manage::Container
  end

  it 'dumps the full project XML to the filestore container' do
    mock_file_field_requests
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    rc.dynamic_model_table = 'test.test_file_field_sf_recs'
    rc.server_url = server_url('file_field')
    rc.records_request_options.exportSurveyFields = true
    rc.data_options.run_jobs_as_user = @user.email
    puts "Project Name: #{rc.name}"
    rc.save
    expect(rc.job_user).to eq @user
    expect(rc.job_app_type).to eq @user.app_type

    rc.dump_archive

    expect(rc.file_store.stored_files.where(path: 'test.test_file_field_sf_recs/project').count).not_to eq 0
  end

  describe 'failed project detection' do
    it 'identifies projects with scheduled_run_failed status as failed' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = '1 hour'
      rc.transfer_mode = 'scheduled'
      rc.save!

      # Update status after save to avoid callback overwriting it
      rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_failed])
      rc.reload

      expect(rc.failed?).to be true
    end

    it 'identifies projects with manual_run_failed status as failed' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = '1 hour'
      rc.transfer_mode = 'scheduled'
      rc.save!

      rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:manual_run_failed])
      rc.reload

      expect(rc.failed?).to be true
    end

    it 'identifies projects with request_failed status as failed' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = '1 hour'
      rc.transfer_mode = 'scheduled'
      rc.save!

      rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:request_failed])
      rc.reload

      expect(rc.failed?).to be true
    end

    it 'does not identify projects without frequency as failed even with failed status' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = nil
      rc.save!

      rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_failed])
      rc.reload

      expect(rc.failed?).to be false
    end

    it 'does not identify projects with successful status as failed' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = '1 hour'
      rc.transfer_mode = 'scheduled'
      rc.save!

      rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_successful])
      rc.reload

      expect(rc.failed?).to be false
    end

    it 'returns the failed_at timestamp' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = '1 hour'
      rc.transfer_mode = 'scheduled'
      rc.save!

      rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_failed])
      rc.reload

      expect(rc.failed_at).to be_present
      expect(rc.failed_at).to be_a(Time)
    end

    it 'finds all failed scheduled projects' do
      # Set up some failed projects
      rc1 = Redcap::ProjectAdmin.active.first
      rc1.current_admin = @admin
      rc1.frequency = '1 hour'
      rc1.transfer_mode = 'scheduled'
      rc1.save!
      rc1.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_failed])

      rc2 = Redcap::ProjectAdmin.active.second
      rc2.current_admin = @admin
      rc2.frequency = '30 minutes'
      rc2.transfer_mode = 'scheduled'
      rc2.save!
      rc2.update_columns(status: Redcap::ProjectAdmin::Statuses[:manual_run_failed])

      failed_projects = Redcap::ProjectAdmin.failed_scheduled_projects
      expect(failed_projects.count).to be >= 2
      expect(failed_projects).to include(rc1)
      expect(failed_projects).to include(rc2)
    end

    it 'detects if any failed scheduled projects exist' do
      # Initially, no failures - update all to successful
      Redcap::ProjectAdmin.active.each do |rc|
        rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_successful])
      end
      expect(Redcap::ProjectAdmin.any_failed_scheduled_projects?).to be false

      # Create a failure
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = '1 hour'
      rc.transfer_mode = 'scheduled'
      rc.save!
      rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_failed])

      expect(Redcap::ProjectAdmin.any_failed_scheduled_projects?).to be true
    end
  end
end
