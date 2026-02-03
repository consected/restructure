# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe NfsStore::Process::DicomDeidentifyJob, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport
  include DicomSupport

  def default_role
    'file1'
  end

  # Helper method to read DICOM file metadata
  def read_dicom_metadata(stored_file)
    stored_file.current_user ||= @user
    fs_path, = stored_file.file_path_and_role_name
    dcm = DICOM::DObject.read(fs_path)
    dcm.to_hash
  end

  # Helper method to reload stored file with current user
  def reload_stored_file(stored_file)
    reloaded = stored_file.class.find(stored_file.id)
    reloaded.current_user = @user
    reloaded
  end

  before :each do
    seed_database && ActivityLog.define_models

    @other_users = Array.new(3) { create_user.first }

    setup_nfs_store
    @activity_log = @container.parent_item

    upload_test_dicom_files
    expect(@uploaded_files.length).to be > 2

    # Verify uploaded DICOM files have expected metadata
    @uploaded_files.each do |ul|
      file_metadata = read_dicom_metadata(ul.stored_file)
      expect(file_metadata["Patient's Name"]).not_to be_blank
      expect(file_metadata['Patient ID']).not_to be_blank
      expect(file_metadata.keys).to include "Patient's Age"
    end

    # Upload specific test files for filter matching
    @substitute_file = upload_file('substitute.dcm', File.read(dicom_file_path('substitute.dcm')))
    @make_copy_file = upload_file('make_copy.dcm', File.read(dicom_file_path('make_copy.dcm')))

    # Now we have uploaded successfully, setup the deidentifier
    setup_deidentifier
    setup_container_and_al
    setup_default_filters

    ul = @uploaded_files.first
    pi = ul.stored_file.container.parent_item
    pi.force_save!
    pi.update! created_at: Time.now, updated_at: Time.now
    expect(@container.parent_item.options_text).to eq pi.options_text
    # expect(@container.parent_item.versioned_definition.updated_at).to eq pi.current_definition.updated_at
    expect(@container.parent_item.options_text).to eq @activity_log.current_definition.options_text
    expect(@container.parent_item.options_text).to eq @aldef.extra_log_types
  end

  it '#overwrite_metadata' do
    sf = @uploaded_files.first.stored_file

    NfsStore::Dicom::MetadataHandler.extract_metadata_from sf

    # Capture original file attributes
    orig_file_name = sf.file_name
    orig_path = sf.path
    orig_file_hash = sf.file_hash
    orig_file_size = sf.file_size
    orig_metadata = sf.file_metadata
    orig_file_metadata = read_dicom_metadata(sf)

    # Apply deidentification
    ph = NfsStore::Process::ProcessHandler.new(sf)
    config = ph.pipeline_job_config(:dicom_deidentify).first
    NfsStore::Dicom::DeidentifyHandler.deidentify_file sf, config

    # Verify changes
    sf = reload_stored_file(sf)
    file_metadata = read_dicom_metadata(sf)

    expect(sf.file_name).to eq orig_file_name
    expect(sf.path).to eq orig_path
    expect(sf.file_hash).not_to eq orig_file_hash
    expect(sf.file_size).not_to eq orig_file_size
    expect(file_metadata).not_to eq orig_file_metadata
    expect(sf.file_metadata).not_to eq orig_metadata
  end

  # The configuration for the pipeline is set in NfsStoreSupport::setup_nfs_store
  it 'runs a dicom_deidentify job on a single stored file' do
    # Use a fresh file for testing
    @uploaded_files.shift
    sf = @uploaded_files.first.stored_file
    sf.current_user = @user

    expect(sf.container.parent_item).to be_a ActivityLog::PlayerContactPhone

    # Verify original metadata
    file_metadata = read_dicom_metadata(sf)
    expect(file_metadata["Patient's Name"]).not_to be_blank
    expect(file_metadata['Patient ID']).not_to be_blank
    expect(file_metadata.keys).to include "Patient's Age"

    # Perform deidentification
    dij = NfsStore::Process::DicomDeidentifyJob.new
    dij.perform(sf, @user.app_type_id)

    # Verify deidentification results
    sf = reload_stored_file(sf)
    file_metadata = read_dicom_metadata(sf)

    expect(file_metadata["Patient's Name"]).to eq 'new value'
    expect(file_metadata['Patient ID']).to eq 'another tagval'
    expect(file_metadata.keys).not_to include "Patient's Age"
  end

  it 'runs a dicom_deidentify with substitutions' do
    sf = @substitute_file.stored_file
    sf.current_user = @user
    parent_item = sf.container.parent_item
    expect(parent_item).to be_a ActivityLog::PlayerContactPhone

    # Verify original metadata
    file_metadata = read_dicom_metadata(sf)
    expect(file_metadata["Patient's Name"]).not_to be_blank
    expect(file_metadata['Patient ID']).not_to be_blank
    expect(file_metadata['Series Description']).not_to be_blank

    # Perform deidentification with substitutions
    dij = NfsStore::Process::DicomDeidentifyJob.new
    dij.perform(sf, @user.app_type_id)

    # Verify substitution results
    sf = reload_stored_file(sf)
    file_metadata = read_dicom_metadata(sf)
    master = sf.container.master

    expect(file_metadata["Patient's Name"]).to eq "do nothing - #{master.id}"
    expect(file_metadata['Patient ID']).to eq "do nothing tagval - #{master.player_contacts.first.data}"
    expect(file_metadata['Series Description']).to eq "got the activity - #{parent_item.data}"
  end

  it 'runs a dicom_deidentify job and generates a new stored file' do
    sf = @make_copy_file.stored_file
    sf.current_user = @user

    expect(sf.container.parent_item).to be_a ActivityLog::PlayerContactPhone

    # Verify original metadata
    file_metadata = read_dicom_metadata(sf)
    expect(file_metadata["Patient's Name"]).not_to be_blank
    expect(file_metadata['Patient ID']).not_to be_blank

    # Perform deidentification (creates copy)
    dij = NfsStore::Process::DicomDeidentifyJob.new
    dij.perform(sf, @user.app_type_id)

    # Verify original file was updated with first filter
    sf = reload_stored_file(sf)
    file_metadata = read_dicom_metadata(sf)
    expect(file_metadata["Patient's Name"]).to eq 'new value'
    expect(file_metadata['Patient ID']).to eq 'another tagval'

    # Verify new copied file was created with second filter
    copied_sf = sf.class.where(path: 'copied-file').first
    copied_sf.current_user = @user
    file_metadata = read_dicom_metadata(copied_sf)

    expect(file_metadata["Patient's Name"]).to eq 'moved'
    expect(file_metadata['Patient ID']).to eq 'moved again'
  end

  # The configuration for the pipeline is set in NfsStoreSupport::setup_nfs_store
  it 'runs a dicom_deidentify job even if the original user has been disabled' do
    # Upload test file
    @make_copy_2_file = upload_file('make_copy_2.dcm', File.read(dicom_file_path('make_copy_2.dcm')))
    sf = @make_copy_2_file.stored_file
    sf.current_user = @user
    original_app_type_id = @user.app_type_id

    expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: @app_type.id)).to be_truthy
    expect(sf.container.parent_item).to be_a ActivityLog::PlayerContactPhone

    # Verify original metadata
    file_metadata = read_dicom_metadata(sf)
    expect(file_metadata["Patient's Name"]).not_to be_blank
    expect(file_metadata['Patient ID']).not_to be_blank

    # Disable the user and verify processing still works with batch user
    @user.update!(disabled: true, current_admin: @admin)
    expect(sf.current_user.disabled).to be true

    sf = reload_stored_file(sf)

    dij = NfsStore::Process::DicomDeidentifyJob.new
    dij.perform(sf, @user.app_type_id, nil, use_pipeline: { user_file_actions: 'disable_check' })

    # Re-enable user for verification
    @user.update!(disabled: false, current_admin: @admin)
    enable_user_app_access(@app_type.name, @user)
    @user.update!(app_type_id: original_app_type_id, current_admin: @admin)

    expect(@user.app_type_id).to eq original_app_type_id
    expect(@user.user_roles.pluck(:role_name)).to include 'nfs_store group 600'

    # Verify file was processed correctly
    sf = reload_stored_file(sf)
    fs_path, = sf.file_path_and_role_name
    expect(fs_path).to be_present

    file_metadata = read_dicom_metadata(sf)
    expect(file_metadata["Patient's Name"]).to eq 'new value'
    expect(file_metadata['Patient ID']).to eq 'another tagval'
    expect(file_metadata.keys).not_to include "Patient's Age"
  end

  # Tests the fix for issue #887: When processing files, if a user's app_type_id differs from the
  # default NFS store app_type_id, the job temporarily updates it to the default during processing
  # to prevent UI breakage, then restores it to the original value after processing completes.
  # This is handled by setup_container_file_current_user which uses a block with ensure to guarantee
  # the restoration happens even if errors occur.
  it 'temporarily updates user app_type_id during processing when it differs from default_app_type_id' do
    # Setup: Create non-default app type and upload test file
    app_type_2 = create_app_type name: 'apptype_test_nfs_non_default', label: 'apptype_test_nfs_non_default'
    enable_user_app_access app_type_2.name, @user

    @make_copy_3_file = upload_file('make_copy_3.dcm', File.read(dicom_file_path('make_copy_3.dcm')))
    sf = @make_copy_3_file.stored_file
    sf.current_user = @user

    original_app_type_id = @user.app_type_id
    expect(original_app_type_id).to eq(Settings.nfs_store_default_app_type_id)
    expect(sf.container.parent_item).to be_a ActivityLog::PlayerContactPhone
    expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: @app_type.id)).to be_truthy

    # Verify original metadata
    file_metadata = read_dicom_metadata(sf)
    expect(file_metadata["Patient's Name"]).not_to be_blank
    expect(file_metadata['Patient ID']).not_to be_blank

    # Change user's app_type_id to non-default value
    @user.update!(app_type_id: app_type_2.id, current_admin: @admin)
    expect(@user.reload.app_type_id).to eq app_type_2.id
    expect(@user.app_type_id).not_to eq Settings.nfs_store_default_app_type_id

    sf = reload_stored_file(sf)

    # Track app_type_id changes during processing
    app_type_id_during_processing = nil
    allow(NfsStore::Dicom::DeidentifyHandler).to receive(:deidentify_file).and_wrap_original do |method, *args|
      app_type_id_during_processing = @user.reload.app_type_id
      method.call(*args)
    end

    # Perform job with non-default app_type_id
    dij = NfsStore::Process::DicomDeidentifyJob.new
    dij.perform(sf, app_type_2.id)

    # Verify transactional app_type_id behavior
    expect(app_type_id_during_processing).to eq(Settings.nfs_store_default_app_type_id)
    expect(@user.reload.app_type_id).to eq(app_type_2.id)

    # Reset user to original app_type_id for file verification
    @user.update!(app_type_id: original_app_type_id, current_admin: @admin)
    expect(@user.app_type_id).to eq original_app_type_id
    expect(@user.user_roles.pluck(:role_name)).to include 'nfs_store group 600'

    # Verify file processing completed correctly
    sf = reload_stored_file(sf)
    fs_path, = sf.file_path_and_role_name
    expect(fs_path).to be_present

    file_metadata = read_dicom_metadata(sf)
    expect(file_metadata["Patient's Name"]).to eq 'new value'
    expect(file_metadata['Patient ID']).to eq 'another tagval'
    expect(file_metadata.keys).not_to include "Patient's Age"
  end
end
