# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe 'Move and rename stored files', type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def default_role
    'file1'
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
  end

  it 'rename a stored file in a container' do
    upload_file 'test-name.txt'
    u = upload_file 'test-name-2.txt'
    upload_file 'test-name-3.txt'

    delfn = 'test-name-2.txt'

    sf = @container.stored_files.where(file_name: delfn).first

    expect(sf).not_to be nil
    expect(sf.file_name).to eq delfn

    new_name = 'new name - ' + sf.file_name
    orig_path = sf.path

    sf.move_to nil, new_name

    sf.reload
    sf.current_user = @user

    expect(sf.path).to eq orig_path
    expect(sf.file_name).to eq new_name

    curr_path = nil
    found = false
    sf.current_user_role_names.each do |role_name|
      curr_path = NfsStore::Manage::Filesystem.nfs_store_path role_name, sf.container, sf.path, sf.file_name
      if File.exist?(curr_path)
        found = true
        break
      end
    end

    expect(found).to be true
  end

  it 'rename an archive file' do
    expect(@app_type).to eq @user&.app_type

    create_filter('.*', role_name: nil)

    orig_count = @container.list_fs_files.length

    upload_file 'test-name-4.txt'

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

    create_filter('.*', resource_name: 'nfs_store__manage__containers', role_name: nil)
    create_filter('.*', resource_name: 'activity_log__player_contact_phones', role_name: nil)

    download = NfsStore::Download.new multiple_items: true, container_ids: [@container.id]
    download.current_user = @user

    setup_access :activity_log__player_contact_phones, resource_type: :table, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, user: @user

    expect(@user.app_type).to eq @app_type
    expect(@activity_log.class.resource_name).to eq 'activity_log__player_contact_phones'
    expect(@activity_log).to eq @container.parent_item
    expect(@activity_log.extra_log_type).to eq :step_1
    expect(@activity_log.resource_name).to eq @activity_log.extra_log_type_config.resource_name
    expect(@user.has_access_to?(:access, :activity_log_type, @activity_log.resource_name))
    expect(@container.parent_item).to eq @activity_log
    expect(@activity_log.current_user).to eq @user
    expect(@container.current_user).to eq @user

    download.retrieve_files_from all_sf_dl

    # Upload the generated zip
    u = upload_file 'test-name.zip', File.read(download.zip_file_path)

    delfn = 'test-name.zip'

    sf = @container.stored_files.where(file_name: delfn).first
    expect(sf).not_to be nil
    expect(sf.file_name).to eq delfn

    af = sf.archived_files.last
    af.current_user = @user
    new_name = 'new name - ' + af.file_name
    orig_path = af.path
    orig_retrieval_path = af.retrieval_path

    af.move_to nil, new_name

    af.reload
    af.current_user = @user
    expect(af.path).to eq orig_path
    expect(af.file_name).to eq new_name

    curr_path = nil

    found = false

    curr_path = af.retrieval_path
    found = true if File.exist?(curr_path) && !File.exist?(orig_retrieval_path)

    expect(found).to be true
  end

  it 'rename a folder of archive files' do
    create_filter('.*', role_name: nil)

    orig_count = @container.list_fs_files.length

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

    f = create_filter('.*', resource_name: 'nfs_store__manage__containers', role_name: nil)
    create_filter('.*', resource_name: 'activity_log__player_contact_phones', role_name: nil)

    download = NfsStore::Download.new multiple_items: true, container_ids: [@container.id]
    download.current_user = @user

    download.retrieve_files_from all_sf_dl

    # Upload the generated zip
    u = upload_file 'test-name-2.zip', File.read(download.zip_file_path)

    delfn = 'test-name-2.zip'

    sf = @container.stored_files.where(file_name: delfn).first
    sf.current_user = @user
    expect(sf).not_to be nil
    expect(sf.file_name).to eq delfn

    afs = sf.archived_files

    expect(afs.length).to be > 1
    af = afs.last
    af.current_user = @user
    from_path = af.path
    in_container = sf.container

    old_ret_paths = {}

    afs.each do |f|
      f.current_user = @user
      old_ret_paths[f.id] = f.retrieval_path
    end

    to_path = 'new path - ' + from_path
    res = NfsStore::Manage::ContainerFile.move_folder in_container, from_path, to_path

    expect(res).to eq afs.length

    sf.reload
    sf.current_user = @user
    new_afs = sf.archived_files

    # Expect the files to have been moved in the database
    num_afs = new_afs.select { |a| a.path == to_path }.length
    expect(num_afs).to eq afs.length

    # Ensure the files are actually in the new path on the filesystem
    new_afs.each do |af|
      found = false
      af.current_user = @user
      curr_path = af.retrieval_path
      old_path = old_ret_paths[af.id]

      found = true if File.exist?(curr_path) && !File.exist?(old_path)

      expect(found).to be true
    end

    # Now move a stored file to a new path

    orig_name = sf.file_name
    orig_path = sf.path
    new_path = "new sf path - #{sf.path}"
    old_path = sf.retrieval_path

    sf.move_to new_path, nil

    sf.reload
    sf.current_user = @user

    expect(sf.path).to eq new_path
    expect(sf.file_name).to eq orig_name

    curr_path = nil

    found = false

    curr_path = sf.retrieval_path

    found = true if File.exist?(curr_path) && !File.exist?(old_path)

    expect(found).to be true
  end
end
