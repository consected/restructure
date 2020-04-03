# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe 'Trash archive files', type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def default_role
    'file1'
  end

  def check
    expect(@activity_log.class.resource_name).to eq 'activity_log__player_contact_phones'
    expect(@activity_log).to eq @container.parent_item
    expect(@activity_log.extra_log_type).to eq :step_1
    expect(@activity_log.resource_name).to eq @activity_log.extra_log_type_config.resource_name
    expect(@user.has_access_to?(:access, :activity_log_type, @activity_log.resource_name))
    expect(@container.parent_item).to eq @activity_log
    expect(@activity_log.current_user).to eq @user
    expect(@container.current_user).to eq @user
  end

  before :all do
    setup_nfs_store
    @activity_log = @container.parent_item
    setup_access :activity_log__player_contact_phones, resource_type: :table, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, user: @user
  end

  before :each do
    @activity_log = @container.parent_item
    @activity_log.extra_log_type = :step_1
    expect(@app_type).to eq @user&.app_type
    create_filter('.*', role_name: nil)
    create_filter('.*', resource_name: 'nfs_store__manage__containers', role_name: nil)
    create_filter('.*', resource_name: 'activity_log__player_contact_phones', role_name: nil)
    setup_access :activity_log__player_contact_phones, resource_type: :table, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, user: @user
  end

  it 'sends an archive file to trash' do
    @container.list_fs_files.length

    upload_file 'test-name-5.txt'

    # Generate a zip file from the uploaded files
    all_sf = @container.stored_files.order(id: :desc).limit(3)

    all_sf_dl = all_sf.map do |sf|
      {
        id: sf.id,
        container_id: @container.id,
        retrieval_type: :stored_file,
        activity_log_type: 'activity_log__player_contact_phone',
        activity_log_id: @activity_log.id

      }
    end

    download = NfsStore::Download.new multiple_items: true, container_ids: [@container.id]
    download.current_user = @user

    check

    download.retrieve_files_from all_sf_dl

    # Upload the generated zip
    delfn = 'test-name-trash.zip'
    upload_file delfn, File.read(download.zip_file_path)
    sf = @container.stored_files.where(file_name: delfn).first
    expect(sf).not_to be nil
    expect(sf.file_name).to eq delfn

    af = sf.archived_files.last
    af.current_user = @user

    af.move_to_trash!

    expect(af.path).to start_with '.trash'
  end

  it 'replaces an archive file' do
    @container.list_fs_files.length
    upload_fn = 'test-name-6.txt'
    upload_file upload_fn

    # Generate a zip file from the uploaded files
    all_sf = @container.stored_files.order(id: :desc).limit(3)

    all_sf_dl = all_sf.map do |sf|
      {
        id: sf.id,
        container_id: @container.id,
        retrieval_type: :stored_file,
        activity_log_type: 'activity_log__player_contact_phone',
        activity_log_id: @activity_log.id

      }
    end

    download = NfsStore::Download.new multiple_items: true, container_ids: [@container.id]
    download.current_user = @user

    check

    download.retrieve_files_from all_sf_dl

    # Upload the generated zip
    delfn = 'test-name-replace.zip'
    upload_file delfn, File.read(download.zip_file_path)
    sf = @container.stored_files.where(file_name: delfn).first
    expect(sf).not_to be nil
    expect(sf.file_name).to eq delfn

    af = sf.archived_files.last
    af.current_user = @user

    txt = 'This is a test file, to check that we replace the content correctly'
    tmp_file = Tempfile.new('replace-test.txt')
    tmp_file.write(txt)
    hash_for_file = Digest::MD5.hexdigest(txt)
    size_for_file = tmp_file.size
    orig_path = af.path.dup
    af.replace_file!(tmp_file.path)

    # Reload the archive file record to ensure the changes have been persisted
    af = NfsStore::Manage::ArchivedFile.find(af.id)
    expect(af.file_hash).to eq hash_for_file
    expect(af.file_size).to eq size_for_file
    expect(af.file_name).to eq upload_fn
    expect(af.path).to eq orig_path
  end
end
