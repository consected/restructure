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

  describe 'transfer mode "none" enforcement' do
    it 'sets frequency to nil when transfer_mode is set to "none"' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = '1 hour'
      rc.transfer_mode = 'none'
      rc.save!

      expect(rc.frequency).to be_nil
    end

    it 'sets frequency to nil when transfer_mode changes to "none"' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = '30 minutes'
      rc.transfer_mode = 'scheduled'
      rc.save!

      expect(rc.frequency).to eq '30 minutes'

      rc.transfer_mode = 'none'
      rc.save!

      expect(rc.frequency).to be_nil
    end

    it 'does not clear frequency when transfer_mode is "scheduled"' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = '1 hour'
      rc.transfer_mode = 'scheduled'
      rc.save!

      expect(rc.frequency).to eq '1 hour'
    end

    it 'does not clear frequency when transfer_mode is "manual"' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.frequency = '2 hours'
      rc.transfer_mode = 'manual'
      rc.save!

      expect(rc.frequency).to eq '2 hours'
    end

    it 'identifies transfer_mode_none? correctly' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.transfer_mode = 'none'
      rc.save!

      expect(rc.transfer_mode_none?).to be true
    end

    it 'identifies transfer_mode_none? as false for other modes' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.transfer_mode = 'scheduled'
      rc.save!

      expect(rc.transfer_mode_none?).to be false

      rc.transfer_mode = 'manual'
      rc.save!

      expect(rc.transfer_mode_none?).to be false
    end

    it 'clears frequency immediately on update to none' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      rc.update!(frequency: '1 hour', transfer_mode: 'scheduled')
      expect(rc.frequency).to eq '1 hour'

      rc.update!(transfer_mode: 'none')
      expect(rc.frequency).to be_nil

      # Verify it persisted
      rc.reload
      expect(rc.frequency).to be_nil
    end
  end

  # Tests for issue #1043: Admin Redcap projects - fails to create new project
  # when admin's matching user is in a non-ref-data app type.
  # The file store container creation should succeed regardless of the admin's
  # current app type, because admin containers use admin_master and the admin NFS role.
  describe 'creating project admin in non-ref-data app type' do
    it 'creates a project and file store container when user is in a different app type' do
      # Ensure all existing projects are disabled so we can create duplicates
      Redcap::ProjectAdmin.update_all(disabled: true)

      # Create a brand new app type with no container access configured
      other_app_type = Admin::AppType.create!(name: "test-no-containers-#{rand(1000)}",
                                              label: 'Test No Containers',
                                              current_admin: @admin)

      # Switch user to the new app type
      enable_user_app_access(other_app_type, @user)
      @user.app_type = other_app_type
      @user.save!
      expect(@user.app_type_id).to eq other_app_type.id

      # Add the admin NFS role for this app type (roles are per-app-type)
      add_user_to_role Settings.admin_nfs_role, for_user: @user
      @user.clear_role_names!
      expect(@user.role_names).to include(Settings.admin_nfs_role)

      # Verify user does NOT have container create access in the new app type
      @user.clear_has_access_to!
      has_container_access = @user.has_access_to?(:create, :table, 'nfs_store__manage__containers',
                                                  force_reset: true)
      expect(has_container_access).to be_falsey

      # Reset admin's memoized matching_user so it picks up the user's current
      # app type (simulates production where the admin's user is freshly loaded)
      @admin.instance_variable_set(:@matching_user, nil)
      expect(@admin.matching_user.app_type_id).to eq other_app_type.id

      p = @projects.first

      # This should NOT raise "This item can not be created" error
      pa = Redcap::ProjectAdmin.create!(
        current_admin: @admin,
        study: Redcap::RedcapSupport::DefaultStudy,
        name: p[:name],
        api_key: p[:api_key],
        server_url: p[:server_url]
      )

      expect(pa).to be_persisted
      expect(pa.file_store).to be_a(NfsStore::Manage::Container)
    end
  end
end
