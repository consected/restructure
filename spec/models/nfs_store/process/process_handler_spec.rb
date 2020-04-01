# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe NfsStore::Process::ProcessHandler, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

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
  end

  before :each do
    @activity_log = @container.parent_item
    @activity_log.extra_log_type = :step_1
    @activity_log.save!
  end

  it 'can access the underlying activity log to get the pipeline definition' do
    al = @container.parent_item
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

    expect(ph.job_list).to eq %i[mount_archive index_files dicom_metadata]
  end
end
