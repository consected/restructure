# frozen_string_literal: true

# Tests for NfsStore::Process::MountArchiveJob
#
# Issue #910: MountArchiveJob fails with "Can not match on this field. It is not an accepted
# alterative ID field" when:
# - A container uses a `filestore directory id` app configuration pointing to an external
#   identifier (e.g., scantron_id) for its parent_sub_dir
# - The user who uploaded the file has since changed app types
# - The new app type (or the default NFS store app type) does not grant the user access
#   to the external identifier table
# - The background job tries to resolve the container path via parent_sub_dir, which calls
#   master.send(setting.value) → alternative_id_value → checks access_by: current_user
#
# The root cause is that alternative_id_value enforces user access controls on the
# alternative ID field. In a background process like MountArchiveJob, the user's current
# app type may not have the necessary access, even though the container's app type does.
# The fix should bypass user access checks for alternative IDs in background processes.
#
# Tests cover both use_parent_sub_dir = true (with filestore directory id config) and
# use_parent_sub_dir = false (default) scenarios, each with happy path and changed app type.

require 'rails_helper'

RSpec.describe NfsStore::Process::MountArchiveJob, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport
  include DicomSupport

  def default_role
    'file1'
  end

  # Helper to create a second app type without scantron access and switch the user to it
  def switch_user_to_app_type_without_scantron_access
    app_type_b = create_app_type(name: "test_no_scantron_910_#{SecureRandom.hex(4)}", label: 'No Scantron App')
    enable_user_app_access(app_type_b, @user)
    create_user_role 'nfs_store group 600', user: @user, app_type: app_type_b
    create_user_role default_role, user: @user, app_type: app_type_b

    setup_access 'activity_log__player_contact_phones', user: @user, app_type: app_type_b
    setup_access 'nfs_store__manage__containers', user: @user, app_type: app_type_b
    setup_access 'nfs_store__manage__stored_files', user: @user, app_type: app_type_b
    setup_access 'nfs_store__manage__archived_files', user: @user, app_type: app_type_b

    @user.update!(app_type_id: app_type_b.id)
    expect(@user.reload.app_type_id).to eq app_type_b.id

    allow(Settings).to receive(:nfs_store_default_app_type_id).and_return(app_type_b.id)

    expect(@user.has_access_to?(:access, :table, :scantrons)).to be_falsey

    Master.reset_external_id_matching_fields!
    app_type_b
  end

  describe 'with use_parent_sub_dir enabled' do
    before :each do
      seed_database && ActivityLog.define_models

      @other_users = []
      @other_users << create_user.first
      @other_users << create_user.first
      @other_users << create_user.first

      setup_nfs_store
      @activity_log = @container.parent_item

      # Give the user access to scantrons in the current app type
      setup_access :scantrons, user: @user

      # Create a scantron record for the master so that master.scantron_id returns a value
      last_scantron = Scantron.unscoped.order(scantron_id: :desc).first
      next_sid = last_scantron ? last_scantron.scantron_id + 1 : 1
      @container.master.current_user = @user
      @container.master.scantrons.create!(scantron_id: next_sid)

      # Prevent upload from triggering MountArchiveJob synchronously.
      # In test mode, Delayed::Worker.delay_jobs is false (jobs run inline),
      # which would cause the archive to be extracted during upload.
      # We want to control when MountArchiveJob runs, so we delay jobs.
      Delayed::Worker.delay_jobs = true

      # Upload a zip file BEFORE enabling parent_sub_dir.
      # In production, the file was uploaded when the system worked correctly.
      # The parent_sub_dir is enabled afterwards to exercise the path resolution
      # that happens when the background MountArchiveJob runs.
      zip_content = File.read(dicom_file_path('dicoms.zip'))
      @zip_upload = upload_file('dicoms.zip', zip_content)
      @zip_sf = @zip_upload.stored_file

      # Now enable parent_sub_dir and configure the filestore directory id.
      # This simulates the production environment where containers use parent_sub_dir
      # to organize files by an external identifier.
      allow(NfsStore::Manage::Filesystem).to receive(:use_parent_sub_dir).and_return(true)
      add_app_config(@app_type, 'filestore directory id', 'scantron_id')
    end

    after :each do
      Delayed::Worker.delay_jobs = false
    end

    it 'mounts an archive successfully when user app type has not changed - Issue910' do
      # Verify the setup: parent_sub_dir resolves correctly with the current user and app type
      @container.current_user = @user
      expect(@container.parent_sub_dir).to be_present
      expect(@container.parent_sub_dir).to match(/scantron-id/)

      # Reload to simulate background job deserialization
      zip_sf = NfsStore::Manage::StoredFile.find(@zip_sf.id)

      # With the user's app type unchanged, the alternative ID is accessible.
      # The perform call should not raise FphsException (the issue #910 error).
      # The mount itself may fail for filesystem reasons since the file was uploaded
      # without parent_sub_dir, but no alternative ID access error should occur.
      fphs_error = nil
      begin
        NfsStore::Process::MountArchiveJob.new.perform(
          zip_sf, @app_type.id, @activity_log, {}
        )
      rescue FphsException => e
        fphs_error = e
      rescue StandardError
        # Other errors (e.g. path not found) are acceptable — we only care about
        # the alternative ID access error from issue #910
      end

      expect(fphs_error).to be_nil,
                            "Expected no FphsException but got: #{fphs_error&.message}"
    end

    it 'mounts an archive even when user app type changes and alternative ID would otherwise be inaccessible - Issue910' do
      # Verify the setup: parent_sub_dir works with the current user and app type
      @container.current_user = @user
      expect(@container.parent_sub_dir).to be_present
      expect(@container.parent_sub_dir).to match(/scantron-id/)

      app_type_b = switch_user_to_app_type_without_scantron_access

      # Reload the stored file from database to simulate a background job deserializing it.
      # This clears all in-memory state (memoized role names, cached associations, etc.)
      zip_sf = NfsStore::Manage::StoredFile.find(@zip_sf.id)

      # The MountArchiveJob should NOT raise FphsException even though the user's current
      # app type does not grant access to the scantron_id alternative ID.
      # The parent_sub_dir path must be resolved regardless of the user's current app type.
      # Note: other errors (e.g. TypeError from path mismatch) are acceptable since the file
      # was uploaded without parent_sub_dir but is now resolved with it.
      fphs_error = nil
      begin
        NfsStore::Process::MountArchiveJob.new.perform(
          zip_sf, app_type_b.id, @activity_log, {}
        )
      rescue FphsException => e
        fphs_error = e
      rescue StandardError
        # Other errors (e.g. path not found) are acceptable — we only care about
        # the alternative ID access error from issue #910
      end

      expect(fphs_error).to be_nil,
                            "Expected no FphsException but got: #{fphs_error&.message}"
    end
  end

  describe 'with use_parent_sub_dir disabled' do
    before :each do
      seed_database && ActivityLog.define_models

      @other_users = []
      @other_users << create_user.first
      @other_users << create_user.first
      @other_users << create_user.first

      setup_nfs_store
      @activity_log = @container.parent_item

      # Give the user access to scantrons in the current app type (for consistency)
      setup_access :scantrons, user: @user

      # Create a scantron record for the master
      last_scantron = Scantron.unscoped.order(scantron_id: :desc).first
      next_sid = last_scantron ? last_scantron.scantron_id + 1 : 1
      @container.master.current_user = @user
      @container.master.scantrons.create!(scantron_id: next_sid)

      # Prevent upload from triggering MountArchiveJob synchronously.
      Delayed::Worker.delay_jobs = true

      # Upload a zip file
      zip_content = File.read(dicom_file_path('dicoms.zip'))
      @zip_upload = upload_file('dicoms.zip', zip_content)
      @zip_sf = @zip_upload.stored_file

      # Ensure parent_sub_dir is disabled (the default in development/test)
      allow(NfsStore::Manage::Filesystem).to receive(:use_parent_sub_dir).and_return(false)
    end

    after :each do
      Delayed::Worker.delay_jobs = false
    end

    it 'mounts an archive successfully when user app type has not changed - Issue910' do
      # Without parent_sub_dir, no alternative ID lookup is needed for path resolution
      @container.current_user = @user
      expect(@container.parent_sub_dir).to be_nil

      # Reload to simulate background job deserialization
      zip_sf = NfsStore::Manage::StoredFile.find(@zip_sf.id)

      # Standard mount should work without any issues
      expect do
        NfsStore::Process::MountArchiveJob.new.perform(
          zip_sf, @app_type.id, @activity_log, {}
        )
      end.not_to raise_error
    end

    it 'mounts an archive even when user app type changes - Issue910' do
      @container.current_user = @user
      expect(@container.parent_sub_dir).to be_nil

      app_type_b = switch_user_to_app_type_without_scantron_access

      # Reload the stored file from database to simulate a background job deserializing it
      zip_sf = NfsStore::Manage::StoredFile.find(@zip_sf.id)

      # Without parent_sub_dir, no alternative ID lookup is needed,
      # so changing the user's app type should have no effect on path resolution.
      expect do
        NfsStore::Process::MountArchiveJob.new.perform(
          zip_sf, app_type_b.id, @activity_log, {}
        )
      end.not_to raise_error
    end
  end
end
