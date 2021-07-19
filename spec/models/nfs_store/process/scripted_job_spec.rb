# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe NfsStore::Process::ScriptedJob, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport
  include DicomSupport
  include ScriptedJobSupport

  def default_role
    'file1'
  end

  before :each do
    seed_database && ::ActivityLog.define_models

    @other_users = []
    @other_users << create_user.first
    @other_users << create_user.first
    @other_users << create_user.first

    # Set up the scripted pipeline
    setup_nfs_store
    setup_scripted_job
    setup_container_and_al activity: :scripted_test
    setup_default_filters activity: :scripted_test

    upload_test_dicom_files
    expect(@uploaded_files.length).to be > 2

    expect(@activity_log.extra_log_type).to eq :scripted_test

    ul = @uploaded_files.first
    pi = ul.stored_file.container.parent_item
    pi.force_save!
    pi.update! created_at: Time.now, updated_at: Time.now
    expect(@container.parent_item.options_text).to eq pi.options_text
    # expect(@container.parent_item.versioned_definition.updated_at).to eq pi.current_definition.updated_at
    expect(@container.parent_item.options_text).to eq @activity_log.current_definition.options_text
    expect(@container.parent_item.options_text).to eq @aldef.extra_log_types
  end

  it 'runs a simple script' do
    ul = @uploaded_files.first
    sf = ul.stored_file
    content = File.read(sf.retrieval_path)
    # The dicom file was altered within the pipeline immediately after storage
    expect(content).to eq "This is new content for the file\n"

    # Get the scripted config from the activity log
    ph = NfsStore::Process::ProcessHandler.new(sf)
    configs = ph.pipeline_job_config(:scripted)

    config = configs.first
    expect(config[:script_filename]).to eq 'simple_job_script.sh'
    res = NfsStore::Scripted::ScriptHandler.run_script sf, config
    expect(res).to be true

    content = File.read(sf.retrieval_path)
    expect(content).to eq "This is other content for the file\n"
  end

  it 'runs a simple script as a job' do
    ul = @uploaded_files[1]
    sf = ul.stored_file
    content = File.read(sf.retrieval_path)
    # The dicom file was altered within the pipeline immediately after storage
    expect(content).to eq "This is new content for the file\n"

    dij = NfsStore::Process::ScriptedJob.new

    curr_app = ul.stored_file.current_user.app_type_id
    dij.perform(sf, curr_app)

    content = File.read(sf.retrieval_path)
    expect(content).to eq "This is other content for the file\n"
  end
end
