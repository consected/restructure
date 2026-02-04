# frozen_string_literal: true

# Feature: Filestore file operations
#   As a user
#   I want to upload, rename, move, download, and send files to trash in the filestore
#   In order that I can manage supporting documents and files
#
# This spec tests the filestore UI operations, specifically:
#   - Uploading single and multiple files to a filestore container
#   - Uploading ZIP archives and verifying extraction
#   - Renaming a file in the filestore
#   - Moving files between folders
#   - Downloading single and multiple files
#   - Sending a file to trash
#
# Regression test for Issue #878:
#   Error when renaming or sending files to trash due to
#   "undefined method 'definition' for class NfsStore::Manage::StoredFile"
#
# The issue was that the JSON serialization of the action result (containing StoredFile objects)
# was calling methods from Dynamic::ImplementationHandler that expected a 'definition' class
# method to exist, which is only present on ActivityLog/DynamicModel implementations.
#
# NOTE: The core bug fix for Issue #878 is validated by the unit test in:
#   spec/models/nfs_store/manage/container_file_spec.rb
#
# This system spec provides UI-level regression testing for the filestore operations.

require 'rails_helper'
require_relative '../../support/nfs_store_feature_support/z_filestore_feature_main'

describe 'Filestore file operations', js: true, driver: $browser_driver, type: :system do
  include FilestoreFeatureMain

  # rubocop:disable Lint/ConstantDefinitionInBlock
  ActivityLogName = 'AL Filter Test 2'
  # rubocop:enable Lint/ConstantDefinitionInBlock

  def set_up_user_access
    puts_debug 'set up user access'
    setup_access :player_contacts, user: @user
    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, user: @user

    # NFS Store access
    setup_access :nfs_store__manage__containers, user: @user
    setup_access :nfs_store__manage__stored_files, user: @user
    setup_access :nfs_store__manage__archived_files, user: @user
    setup_access :download_files, resource_type: :general, access: :read, user: @user
    setup_access :send_files_to_trash, resource_type: :general, access: :read, user: @user
    setup_access :move_files, resource_type: :general, access: :read, user: @user

    # Create NFS store role
    create_user_role 'nfs_store group 600', user: @user, app_type: @user.app_type

    expect(@user.has_access_to?(:read, :general, :app_type)).to be_truthy
    expect(@user.has_access_to?(:access, :table, :player_contacts)).to be_truthy

    puts_debug 'done setting up user access'
  end

  def expand_phone_log_tab
    expand_master_record_tab('activity_log__player_contact_phones')
  end

  before :all do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)

    # Setup activity log definitions first
    SetupHelper.setup_al_gen_tests ActivityLogName, nil, 'player_contact', rec_type: 'phone'

    # Create user first
    create_user(create_master: false)
    expect(@user.has_access_to?(:read, :general, :app_type)).to be_truthy

    SetupHelper.feature_setup

    # Create admin for configuring activity log
    create_admin unless @admin

    @app_type = @user.app_type

    # Setup filestore directories
    test_dir = File.join(
      NfsStore::Manage::Filesystem.nfs_store_directory,
      "#{NfsStore::Manage::Group::NfsMountNamePrefix}600",
      "app-type-#{@app_type.id}",
      'containers'
    )
    FileUtils.rm_rf test_dir
    FileUtils.mkdir_p test_dir

    # Find and configure the activity log definition
    @aldef = ActivityLog.active.where(name: ActivityLogName).first
    expect(@aldef).not_to be_nil

    # Configure step_1 with filestore
    @aldef.extra_log_types = <<~ENDDEF
      step_1:
        label: Step 1
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          on_create:
            create_filestore_container:
              name:
                - session files
                - select_scanner
              label: Session Files
              create_with_role: nfs_store group 600

        references:
          nfs_store__manage__container:
            label: Files
            from: this
            add: one_to_this
            view_as:
              edit: hide
              show: filestore
              new: not_embedded

        nfs_store:
          pipeline:
            - mount_archive:
            - index_files:
          can:
            send_files_to_trash_if:
              always: true
            move_files_if:
              always: true
            user_file_actions_if:
              always: true
    ENDDEF

    @aldef.current_admin = @admin
    @aldef.save!
    @aldef.option_configs(force: true)
    ActivityLog.define_models
    ActivityLog::PlayerContactPhone.definition.option_configs(force: true)

    # Set up user access before creating test data
    set_up_user_access

    # Setup NFS store filters
    resource_name = 'activity_log__player_contact_phone__step_1'
    NfsStore::Filter::Filter.active.where(app_type: @app_type, resource_name:).update_all(disabled: true)
    NfsStore::Filter::Filter.create!(
      current_admin: @admin,
      app_type: @app_type,
      role_name: nil,
      user: nil,
      resource_name:,
      filter: '.*'
    )

    # Create test data in before :all so it's committed to the database
    # and visible to the browser's HTTP requests (which use a separate connection)
    @master = create_master
    @player_contact = @master.player_contacts.create!(
      data: rand(10_000_000_000_000_000),
      rank: 10,
      rec_type: :phone
    )
    @player_contact.master.current_user = @user

    # Create the activity log with filestore
    @activity_log = ActivityLog::PlayerContactPhone.create!(
      select_call_direction: 'from player',
      select_who: 'user',
      extra_log_type: :step_1,
      player_contact: @player_contact,
      master: @master
    )
    expect(@activity_log).to be_persisted
    @container = @activity_log.model_references&.first&.to_record
    expect(@container).to be_a(NfsStore::Manage::Container)
  end

  before :each do
    # Re-use the user created in before :all (don't create a new one)
    # This follows the pattern from switch_id_display_spec.rb
    validate_setup
    login
    expect(User.find(@user.id).app_type_id).to eq @app_type.id
  end

  after :all do
    # Clean up temp files
    temp_dir = Rails.root.join('tmp', 'test_files')
    FileUtils.rm_rf(temp_dir)
  end

  describe 'File upload and rename' do
    it 'uploads a file and renames it without errors (regression for issue #878)' do
      # Navigate to the master record
      navigate_to_master(@master.id)

      # Expand the phone log tab
      expand_phone_log_tab

      # Wait for activity log entries to load
      expect(page).to have_css('.activity-log--player-contact-phones-block', wait: 15)

      # The filestore should already be visible in the step_1 activity log entry
      # Wait for the filestore container to be visible
      wait_for_filestore_container

      # Create and upload a test file
      original_filename = "test-doc-#{SecureRandom.hex(4)}.txt"
      test_file_path = create_temp_test_file(filename: original_filename)
      upload_file_to_filestore(test_file_path)

      # Verify the file appears in the browser
      expect(file_exists_in_browser?(original_filename)).to be true

      # Select the file
      select_file_in_browser(original_filename)

      # Open the hamburger menu
      open_filestore_menu

      # Click rename file
      click_rename_file_menu_item

      # Enter new name and submit
      new_filename = "renamed-doc-#{SecureRandom.hex(4)}.txt"
      rename_file_to(new_filename)

      # Verify no error occurred (this was the bug in issue #878)
      expect(has_error_alert?).to be(false), "Unexpected error: #{error_alert_text}"

      # Refresh the list and verify the renamed file appears
      refresh_filestore_list
      expect(file_exists_in_browser?(new_filename)).to be true
      expect(file_exists_in_browser?(original_filename)).to be false
    end
  end

  describe 'Send file to trash' do
    it 'sends a file to trash without errors (regression for issue #878)' do
      # Navigate to the master record
      navigate_to_master(@master.id)

      # Expand the phone log tab
      expand_phone_log_tab

      # Wait for the filestore container to be visible
      wait_for_filestore_container

      # Create and upload a test file
      filename = "trash-test-#{SecureRandom.hex(4)}.txt"
      test_file_path = create_temp_test_file(filename:)
      upload_file_to_filestore(test_file_path)

      # Verify the file appears in the browser
      expect(file_exists_in_browser?(filename)).to be true

      # Select the file
      select_file_in_browser(filename)

      # Open the hamburger menu
      open_filestore_menu

      # Click send to trash
      click_send_to_trash_menu_item

      # Verify no error occurred (this was the bug in issue #878)
      expect(has_error_alert?).to be(false), "Unexpected error: #{error_alert_text}"

      # Refresh the list and verify the file is gone
      refresh_filestore_list
      expect(file_exists_in_browser?(filename)).to be false
    end
  end

  describe 'Multiple file upload' do
    it 'uploads multiple files in a single request' do
      # Navigate to the master record
      navigate_to_master(@master.id)

      # Expand the phone log tab
      expand_phone_log_tab

      # Wait for the filestore container to be visible
      wait_for_filestore_container

      # Create multiple test files
      file1 = create_temp_test_file(filename: "multi-file1-#{SecureRandom.hex(4)}.txt", content: 'File 1 content')
      file2 = create_temp_test_file(filename: "multi-file2-#{SecureRandom.hex(4)}.txt", content: 'File 2 content')
      file3 = create_temp_test_file(filename: "multi-file3-#{SecureRandom.hex(4)}.txt", content: 'File 3 content')

      # Upload all files at once
      upload_multiple_files_to_filestore([file1, file2, file3])

      # Verify all files appear in the browser
      expect(file_exists_in_browser?(File.basename(file1))).to be true
      expect(file_exists_in_browser?(File.basename(file2))).to be true
      expect(file_exists_in_browser?(File.basename(file3))).to be true

      # Verify no errors occurred
      expect(has_error_alert?).to be(false), "Unexpected error: #{error_alert_text}"
    end
  end

  describe 'ZIP archive upload and extraction' do
    it 'uploads dicoms.zip and verifies its contents are extracted' do
      # Navigate to the master record
      navigate_to_master(@master.id)

      # Expand the phone log tab
      expand_phone_log_tab

      # Wait for the filestore container to be visible
      wait_for_filestore_container

      # Upload the dicoms.zip fixture file
      dicoms_zip_path = fixture_file_path('dicom/dicoms.zip')
      expect(File.exist?(dicoms_zip_path)).to be(true), "Fixture file not found: #{dicoms_zip_path}"

      upload_file_to_filestore(dicoms_zip_path, wait_for_processing: true)

      # Verify the zip file appears in the browser
      expect(file_exists_in_browser?('dicoms.zip')).to be true

      # Verify no errors occurred during upload
      expect(has_error_alert?).to be(false), "Unexpected error during upload: #{error_alert_text}"

      # Wait for the archive to be extracted (this may take some time)
      # The pipeline processes zip files and extracts their contents
      wait_for_archive_extraction('dicoms.zip', timeout: 90)

      # Verify the extracted archive folder exists
      expect(archive_folder_exists_in_browser?('dicoms.zip')).to be true
    end
  end

  describe 'Move file to folder' do
    it 'moves a file from one directory to another' do
      # Navigate to the master record
      navigate_to_master(@master.id)

      # Expand the phone log tab
      expand_phone_log_tab

      # Wait for the filestore container to be visible
      wait_for_filestore_container

      # Create and upload a test file
      filename = "move-test-#{SecureRandom.hex(4)}.txt"
      test_file_path = create_temp_test_file(filename:)
      upload_file_to_filestore(test_file_path)

      # Verify the file appears in the browser
      expect(file_exists_in_browser?(filename)).to be true

      # Select the file
      select_file_in_browser(filename)

      # Open the hamburger menu
      open_filestore_menu

      # Click move files
      click_move_files_menu_item

      # Move to a new folder
      new_folder_name = "test-folder-#{SecureRandom.hex(4)}"
      move_files_to_folder(new_folder_name)

      # Verify no error occurred
      expect(has_error_alert?).to be(false), "Unexpected error: #{error_alert_text}"

      # Refresh the list
      refresh_filestore_list

      # Verify the folder exists
      expect(folder_exists_in_browser?(new_folder_name)).to be true

      # Expand the folder and verify the file is inside
      expand_folder(new_folder_name)
      expect(file_exists_in_browser?(filename)).to be true
    end
  end

  describe 'File download' do
    it 'downloads a single file' do
      # Navigate to the master record
      navigate_to_master(@master.id)

      # Expand the phone log tab
      expand_phone_log_tab

      # Wait for the filestore container to be visible
      wait_for_filestore_container

      # Create and upload a test file
      filename = "download-single-#{SecureRandom.hex(4)}.txt"
      content = "Test content for download - #{SecureRandom.hex}"
      test_file_path = create_temp_test_file(filename:, content:)
      upload_file_to_filestore(test_file_path)

      # Verify the file appears in the browser
      expect(file_exists_in_browser?(filename)).to be true

      # Select the file
      select_file_in_browser(filename)

      # Click the download button
      # Note: In headless mode, the download happens but we can't easily verify
      # the file was saved. We verify that the button click doesn't cause errors.
      click_download_button

      # Verify no error occurred
      expect(has_error_alert?).to be(false), "Unexpected error: #{error_alert_text}"
    end

    it 'downloads multiple files as a zip' do
      # Navigate to the master record
      navigate_to_master(@master.id)

      # Expand the phone log tab
      expand_phone_log_tab

      # Wait for the filestore container to be visible
      wait_for_filestore_container

      # Create and upload multiple test files
      file1_name = "download-multi1-#{SecureRandom.hex(4)}.txt"
      file2_name = "download-multi2-#{SecureRandom.hex(4)}.txt"
      file1_path = create_temp_test_file(filename: file1_name, content: 'Multi download file 1')
      file2_path = create_temp_test_file(filename: file2_name, content: 'Multi download file 2')

      upload_file_to_filestore(file1_path)
      upload_file_to_filestore(file2_path)

      # Verify both files appear in the browser
      expect(file_exists_in_browser?(file1_name)).to be true
      expect(file_exists_in_browser?(file2_name)).to be true

      # Select both files
      select_multiple_files_in_browser([file1_name, file2_name])

      # Click the download button
      # When multiple files are selected, they download as a zip archive
      click_download_button

      # Verify no error occurred
      expect(has_error_alert?).to be(false), "Unexpected error: #{error_alert_text}"
    end
  end
end
