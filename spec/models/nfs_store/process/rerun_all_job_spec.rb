# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe NfsStore::Process::RerunAllJob, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport
  include DicomSupport

  def default_role
    'file1'
  end

  def do_dicom_test_uploads; end

  before :each do
    seed_database && ::ActivityLog.define_models

    @other_users = []
    @other_users << create_user.first
    @other_users << create_user.first
    @other_users << create_user.first

    setup_nfs_store
    @activity_log = @container.parent_item

    upload_test_zip_file
    expect(@uploaded_files.length).to be > 0

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

  # The configuration for the pipeline is set in NfsStoreSupport::setup_nfs_store
  it 'runs a job to rerun all jobs on a single stored file' do
    # Make sure we are working with a new file

    ul = @uploaded_files.first
    sf = ul.stored_file
    sf.current_user = @user
    sf.update!(last_process_name_run: '_all_done_')

    expect(sf.container.parent_item).to be_a ActivityLog::PlayerContactPhone

    expect(sf.last_process_name_run).to eq '_all_done_'

    dij = NfsStore::Process::RerunAllJob.new

    dij.perform(sf, @user.app_type_id)

    # Brute force reload the file
    sf = sf.class.find(sf.id)
    sf.current_user = @user
    expect(sf.last_process_name_run).to be nil
  end
end
