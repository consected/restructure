# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe NfsStore::Process::ProcessHandler, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport
  include DicomSupport

  def default_role
    'file1'
  end

  before :all do
    @other_users = []
    @other_users << create_user.first
    @other_users << create_user.first
    @other_users << create_user.first

    seed_database && ::ActivityLog.define_models
    # setup_nfs_store
    # setup_deidentifier
  end

  before :each do
    setup_nfs_store
    setup_deidentifier
    setup_container_and_al
    setup_default_filters
  end

  it 'can access the underlying activity log to get the pipeline definition' do
    al = @activity_log
    expect(al).to be_a ActivityLog::PlayerContactPhone
    expect(al.resource_name).to eq 'activity_log__player_contact_phone__step_1'
    expect(al.extra_log_type_config.nfs_store).to be_a Hash

    pl = al.extra_log_type_config.nfs_store[:pipeline]
    expect(pl).to be_a Array

    expect(pl[-2].first.first).to eq :dicom_deidentify
    pli = pl[-2].first.last

    expect(pli[0]).to be_a Hash
    expect(pli[0].first.first).to eq :file_filters
    expect(pli[0].first.last).to be_a Array
    expect(pli[0][:set_tags]).to be_a Hash
  end

  it 'defines a custom pipeline' do
    dicom_content = File.read Rails.root.join('docs', 'dicom1.dcm')
    ul = upload_file 'dicom1.dcm', dicom_content
    sf = ul.stored_file

    expect(sf.container.parent_item).to be_a ActivityLog::PlayerContactPhone

    ph = NfsStore::Process::ProcessHandler.new sf

    expect(ph.job_list).to eq %i[mount_archive index_files dicom_deidentify dicom_metadata]
  end

  it 'runs a single job outside of the pipeline' do
    f = 'make_copy.dcm'
    dicom_content = File.read(dicom_file_path(f))
    @make_copy_file = upload_file(f, dicom_content)

    ul = @make_copy_file
    sf = ul.stored_file
    sf.current_user = @user

    name = 'index_files'
    NfsStore::Process::ProcessHandler.new(sf, do_not_run_job_after: true).run(name)

    expect(sf.last_process_name_run.to_s).to eq name
  end

  it 'runs user_file_actions pipeline' do
    f = '000000.dcm'
    dicom_content = File.read(dicom_file_path(f))
    ul = upload_file(f, dicom_content)
    sf = ul.stored_file
    sf.current_user = @user

    ph = NfsStore::Process::ProcessHandler.new(sf, use_pipeline: { user_file_actions: 're_identify' })
    expect(ph.job_list).to eq %i[dicom_deidentify dicom_metadata]
    ph.run_all

    # Force reload of the file
    sf = sf.class.find(sf.id)
    sf.current_user = @user

    expect(sf.file_metadata["Patient's Name"]).to eq sf.master_id.to_s
    expect(sf.file_metadata['Patient ID']).to eq sf.master.player_contacts.first.data
  end

  it 'runs user_file_actions pipeline with multiple files' do
    sfs = []
    f = '000001.dcm'
    dicom_content = File.read(dicom_file_path(f))
    ul = upload_file(f, dicom_content)
    sf = ul.stored_file
    sf.current_user = @user
    sfs << sf

    f = '000002.dcm'
    dicom_content = File.read(dicom_file_path(f))
    ul = upload_file(f, dicom_content)
    sf = ul.stored_file
    sf.current_user = @user
    sfs << sf

    ph = NfsStore::Process::ProcessHandler.new(sfs, use_pipeline: { user_file_actions: 're_identify' })
    expect(ph.job_list).to eq %i[dicom_deidentify dicom_metadata]
    ph.run_all

    # Force reload of the file
    sf = sfs[0]
    sf = sf.class.find(sf.id)
    expect(sf.file_metadata["Patient's Name"]).to eq sf.master_id.to_s
    expect(sf.file_metadata['Patient ID']).to eq sf.master.player_contacts.first.data

    sf = sfs[1]
    sf = sf.class.find(sf.id)
    expect(sf.file_metadata["Patient's Name"]).to eq sf.master_id.to_s
    expect(sf.file_metadata['Patient ID']).to eq sf.master.player_contacts.first.data
  end

  it 'runs user_file_actions pipeline named reidentify with multiple files' do
    create_filter('.*', role_name: nil, user: @user, resource_name: @activity_log.resource_name)

    sfs = []
    f = '000003.dcm'
    dicom_content = File.read(dicom_file_path(f))
    ul = upload_file(f, dicom_content)
    sf = ul.stored_file
    sf.current_user = @user
    sfs << sf

    f = '000004.dcm'
    dicom_content = File.read(dicom_file_path(f))
    ul = upload_file(f, dicom_content)
    sf = ul.stored_file
    sf.current_user = @user
    sfs << sf

    rets = []
    sfs.each do |h|
      rets << {
        id: h['id'].to_i,
        container_id: @container.id,
        retrieval_type: :stored_file,
        activity_log_type: @activity_log.extra_log_type,
        activity_log_id: @activity_log.id
      }
    end

    ufa = NfsStore::UserFileAction.new container_id: sf.container.id, multiple_items: true, activity_log: @activity_log, current_user: @user

    expect do
      ufa.perform_action(rets, 'reidentify_copy')
    end.to raise_error FsException::NoAccess

    setup_access 'user_file_actions', resource_type: :general, user: @user, access: :read

    expect(@user.has_access_to?(:read, :general, :user_file_actions)).to be_truthy
    expect(@user.can?(:user_file_actions))

    # Create a new request to reflect the new access controls
    ufa = NfsStore::UserFileAction.new container_id: sf.container.id, multiple_items: true, activity_log: @activity_log, current_user: @user

    items = ufa.perform_action(rets, 'reidentify_copy')
    expect(items.length).to eq 2

    # The originals should be unchanged
    sfs.each do |sf1|
      sf1 = sf1.class.find(sf1.id)
      sf1.current_user = @user
      expect(sf1.file_metadata["Patient's Name"]).to eq 'new value'
      expect(sf1.file_metadata['Patient ID']).to eq 'another tagval'
    end

    # The copies should have the new location and values
    sfs1 = @container.stored_files.where(path: 'copy-location')
    expect(sfs.count).to eq 2
    sfs1.each do |sf1|
      expect(sf1.file_metadata["Patient's Name"]).to eq sf.master_id.to_s
      expect(sf1.file_metadata['Patient ID']).to eq sf.master.player_contacts.first.data
      expect(sf1.path).to eq 'copy-location'
    end
  end
end
