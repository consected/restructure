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

    dij = NfsStore::Process::DicomDeidentifyJob.new
    dij.deidentify_file sf

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

  it 'runs a dicom_deidentify job on a single stored file' do
    ul = @uploaded_files.first
    sf = ul.stored_file

    expect(sf.container.parent_item).to be_a ActivityLog::PlayerContactPhone

    dij = NfsStore::Process::DicomDeidentifyJob.new

    dij.perform(sf)
  end
end
