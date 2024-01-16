# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe 'Delete stored files', type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def default_role
    'file1'
  end

  before :example do
    # setup_nfs_store
  end

  before :each do
    setup_nfs_store
    setup_container_and_al
    setup_default_filters
  end

  it 'delete a stored file from a container' do
    upload_file 'test-name.txt'
    u = upload_file 'test-name-2.txt'
    upload_file 'test-name-3.txt'

    delfn = 'test-name-2.txt'
    trashdir = '.trash'

    sf = @container.stored_files.where(file_name: delfn).first

    expect(sf).not_to be nil
    expect(sf.file_name).to eq delfn

    dt = DateTime.now.to_i
    sf.move_to_trash!
    expect(sf.path).to eq trashdir

    curr_path = nil

    sf.current_user_role_names.each do |role_name|
      curr_path = NfsStore::Manage::Filesystem.nfs_store_path role_name, sf.container, sf.path, sf.file_name
      break if File.exist?(curr_path)
    end

    expect(curr_path).to end_with("#{trashdir}/#{delfn}--#{dt}") || end_with("#{trashdir}/#{delfn}--#{dt - 1}")

    expect(NfsStore::Upload.hash_for_file(curr_path)).to eq u.file_hash

    non_trash_sf = @container.stored_files

    expect(non_trash_sf.count).to eq 2

    fs = @container.list_fs_files
    expect(fs.length).to eq 2
  end

  it 'delete a stored zip file but retain its exploded archive files' do
    setup_nfs_store
    setup_container_and_al
    al = @activity_log
    expect(al).to be_a ActivityLog::PlayerContactPhone
    expect(@container.parent_item).to eq al
    expect(al.resource_name).to eq 'activity_log__player_contact_phone__step_1'
    expect(al.model_references.length).to eq 1

    orig_count = @container.list_fs_files.length

    upload_file 'test-name-4.txt'
    upload_file 'test-name-5.txt'
    upload_file 'test-name-6.txt'

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

    setup_default_filters

    download = NfsStore::Download.new multiple_items: true, container_ids: [@container.id]
    download.current_user = @user

    expect(@container.parent_item).not_to be nil
    download.retrieve_files_from all_sf_dl

    # Upload the generated zip
    u = upload_file 'test-name.zip', File.read(download.zip_file_path)

    delfn = 'test-name.zip'
    trashdir = '.trash'

    sf = @container.stored_files.where(file_name: delfn).first
    expect(sf).not_to be nil
    expect(sf.file_name).to eq delfn

    count_afs = sf.archived_files.length

    dt = DateTime.now.to_i
    sf.move_to_trash!
    expect(sf.path).to eq trashdir

    curr_path = nil

    sf.current_user_role_names.each do |role_name|
      curr_path = NfsStore::Manage::Filesystem.nfs_store_path role_name, sf.container, sf.path, sf.file_name
      break if File.exist?(curr_path)
    end

    expect(curr_path).to end_with("#{trashdir}/#{delfn}--#{dt}") || end_with("#{trashdir}/#{delfn}--#{dt - 1}")

    expect(NfsStore::Upload.hash_for_file(curr_path)).to eq u.file_hash

    non_trash_sf = @container.stored_files
    expect(non_trash_sf.count).to eq 3

    non_trash_af = @container.archived_files
    expect(non_trash_af.count).to eq count_afs

    fs = @container.list_fs_files
    expect(fs.length).to eq 3 + count_afs + orig_count

    af = sf.archived_files.last
    af.current_user = @user
    af.move_to_trash!

    non_trash_af = @container.archived_files
    expect(non_trash_af.count).to eq(count_afs - 1)
  end

  it 'delete a stored file from a container and allows new upload' do
    upload_file 'test-name-7.txt'
    upload_file 'test-name-8.txt'
    upload_file 'test-name-9.txt'

    delfn = 'test-name-7.txt'

    sf = @container.stored_files.where(file_name: delfn).first

    expect(sf).not_to be nil
    expect(sf.file_name).to eq delfn

    non_trash_sf = @container.stored_files
    expect(non_trash_sf.count).to eq 3

    expect do
      NfsStore::Upload.find_upload @container, sf.file_hash, delfn, @user, path: sf.path
    end.to raise_error(FsException::Action, 'A matching stored file already exists')

    sf.move_to_trash!

    non_trash_sf = @container.stored_files
    expect(non_trash_sf.count).to eq 2

    again = NfsStore::Upload.find_upload @container, sf.file_hash, delfn, @user, path: sf.path
    expect(again).to be nil

    upload_file delfn
    sf = @container.stored_files.where(file_name: delfn).first

    expect do
      NfsStore::Upload.find_upload @container, sf.file_hash, delfn, @user, path: sf.path
    end.to raise_error(FsException::Action, 'A matching stored file already exists')

    sleep 2 # to ensure the move to trash timestamp is ok
    sf.move_to_trash!
  end
end
