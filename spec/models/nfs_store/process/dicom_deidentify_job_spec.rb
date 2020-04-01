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

  before :all do
    ::ActivityLog.define_models

    @other_users = []
    @other_users << create_user.first
    @other_users << create_user.first
    @other_users << create_user.first

    setup_nfs_store
    @activity_log = @container.parent_item

    upload_test_dicom_files
    expect(@uploaded_files.length).to be > 2

    i = 0
    @uploaded_files.each do |ul|
      sf = ul.stored_file
      sf.current_user = @user
      fs_path, = sf.file_path_and_role_name
      dcm = DICOM::DObject.read(fs_path)
      file_metadata = dcm.to_hash
      expect(file_metadata["Patient's Name"]).not_to be_blank
      expect(file_metadata['Patient ID']).not_to be_blank
      expect(file_metadata.keys).to include "Patient's Age"
      i += 1
    end

    # Use a file named so the filter will match
    f = 'substitute.dcm'
    dicom_content = File.read(dicom_file_path(f))
    @substitute_file = upload_file(f, dicom_content)
    f = 'make_copy.dcm'
    dicom_content = File.read(dicom_file_path(f))
    @make_copy_file = upload_file(f, dicom_content)

    # Now we have uploaded successfully, setup the deidentifier
    setup_deidentifier
  end

  before :each do
    @activity_log = @container.parent_item
    @activity_log.extra_log_type = :step_1
    @activity_log.save!
  end

  it '#overwrite_metadata' do
    ul = @uploaded_files.first
    sf = ul.stored_file

    dmj = NfsStore::Process::DicomMetadataJob.new
    dmj.extract_metadata sf

    orig_file_name = sf.file_name
    orig_path = sf.path
    orig_file_hash = sf.file_hash
    orig_file_size = sf.file_size
    orig_fs_path, = sf.file_path_and_role_name
    orig_metadata = sf.file_metadata

    dcm = DICOM::DObject.read(orig_fs_path)
    orig_file_metadata = dcm.to_hash

    # Get the deidentify config from the activity log
    configs = NfsStore::Process::ProcessHandler.pipeline_job_config(sf, :dicom_deidentify)

    config = configs.first
    NfsStore::Dicom::DeidentifyHandler.deidentify_file sf, config

    # Brute force reload the file
    sf = sf.class.find(sf.id)
    sf.current_user = @user
    fs_path, = sf.file_path_and_role_name

    dcm = DICOM::DObject.read(fs_path)
    file_metadata = dcm.to_hash

    expect(sf.file_name).to eq orig_file_name
    expect(sf.path).to eq orig_path
    expect(sf.file_hash).not_to eq orig_file_hash
    expect(sf.file_size).not_to eq orig_file_size
    expect(file_metadata).not_to eq orig_file_metadata
    expect(sf.file_metadata).not_to eq orig_metadata
  end

  # The configuration for the pipeline is set in NfsStoreSupport::setup_nfs_store as:
  #
  # nfs_store:
  #   pipeline:
  #     - mount_archive:
  #     - index_files:

  #     - dicom_deidentify:
  #       - file_filters: .*
  #         recursive: true
  #         set_tags:
  #           '0010,0010': new value
  #           '0010,0020': another tagval
  #         delete_tags:
  #           - '0010,1010'
  #      - file_filters: substitute.dcm
  #        recursive: true
  #        set_tags:
  #          '0010,0010': do nothing - {{master_id}}
  #          '0010,0020': do nothing tagval - {{player_contacts.data}}
  #          '0008,103E': got the activity - {{parent_item.data}}
  #     - dicom_metadata:
  #
  #
  it 'runs a dicom_deidentify job on a single stored file' do
    # Make sure we are working with a new file
    @uploaded_files.shift

    ul = @uploaded_files.first
    sf = ul.stored_file
    sf.current_user = @user

    expect(sf.container.parent_item).to be_a ActivityLog::PlayerContactPhone

    # Get the original metadata
    fs_path, = sf.file_path_and_role_name
    dcm = DICOM::DObject.read(fs_path)
    file_metadata = dcm.to_hash

    puts file_metadata

    expect(file_metadata["Patient's Name"]).not_to be_blank
    expect(file_metadata['Patient ID']).not_to be_blank
    expect(file_metadata.keys).to include "Patient's Age"

    dij = NfsStore::Process::DicomDeidentifyJob.new

    dij.perform(sf)

    # Brute force reload the file
    sf = sf.class.find(sf.id)
    sf.current_user = @user
    fs_path, = sf.file_path_and_role_name
    dcm = DICOM::DObject.read(fs_path)
    file_metadata = dcm.to_hash
    puts file_metadata
    expect(file_metadata["Patient's Name"]).to eq 'new value'
    expect(file_metadata['Patient ID']).to eq 'another tagval'
    expect(file_metadata.keys).not_to include "Patient's Age"
  end

  it 'runs a dicom_deidentify with substitutions' do
    sf = @substitute_file.stored_file
    sf.current_user = @user
    parent_item = sf.container.parent_item
    expect(parent_item).to be_a ActivityLog::PlayerContactPhone

    # Get the original metadata
    fs_path, = sf.file_path_and_role_name
    dcm = DICOM::DObject.read(fs_path)
    file_metadata = dcm.to_hash

    puts file_metadata

    expect(file_metadata["Patient's Name"]).not_to be_blank
    expect(file_metadata['Patient ID']).not_to be_blank
    expect(file_metadata['Series Description']).not_to be_blank

    dij = NfsStore::Process::DicomDeidentifyJob.new

    dij.perform(sf)

    # Brute force reload the file
    sf = sf.class.find(sf.id)
    sf.current_user = @user
    fs_path, = sf.file_path_and_role_name
    dcm = DICOM::DObject.read(fs_path)
    file_metadata = dcm.to_hash

    master = sf.container.master

    expect(file_metadata["Patient's Name"]).to eq "do nothing - #{master.id}"
    expect(file_metadata['Patient ID']).to eq "do nothing tagval - #{master.player_contacts.first.data}"
    expect(file_metadata['Series Description']).to eq "got the activity - #{parent_item.data}"
  end

  it 'runs a dicom_deidentify job and generates a new stored file' do
    ul = @make_copy_file
    sf = ul.stored_file
    sf.current_user = @user

    expect(sf.container.parent_item).to be_a ActivityLog::PlayerContactPhone

    # Get the original metadata
    fs_path, = sf.file_path_and_role_name
    dcm = DICOM::DObject.read(fs_path)
    file_metadata = dcm.to_hash

    puts file_metadata

    expect(file_metadata["Patient's Name"]).not_to be_blank
    expect(file_metadata['Patient ID']).not_to be_blank

    dij = NfsStore::Process::DicomDeidentifyJob.new

    dij.perform(sf)

    # Brute force reload the file
    sf = sf.class.find(sf.id)
    sf.current_user = @user
    fs_path, = sf.file_path_and_role_name
    dcm = DICOM::DObject.read(fs_path)
    file_metadata = dcm.to_hash

    # The original file should not have changed, beyond what was in the first matching filter
    expect(file_metadata["Patient's Name"]).to eq 'new value'
    expect(file_metadata['Patient ID']).to eq 'another tagval'

    # The new file should be at a new path
    sf = sf.class.where(path: 'copied-file').first
    sf.current_user = @user
    fs_path, = sf.file_path_and_role_name
    dcm = DICOM::DObject.read(fs_path)
    file_metadata = dcm.to_hash

    expect(file_metadata["Patient's Name"]).to eq 'moved'
    expect(file_metadata['Patient ID']).to eq 'moved again'
  end
end
