require 'rails_helper'
require 'securerandom'

RSpec.describe "Delete stored files", type: :model do

  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  DefaultRole = 'file1'

  before :all do
    setup_nfs_store
  end

  it "delete a stored file from a container" do
    upload_file 'test-name.txt'
    u = upload_file 'test-name-2.txt'
    upload_file 'test-name-3.txt'

    delfn = 'test-name-2.txt'
    trashdir = '.trash'

    sf = @container.stored_files.where(file_name: delfn).first

    expect(sf).not_to be nil
    expect(sf.file_name).to eq delfn

    sf.move_to_trash!
    expect(sf.path).to eq trashdir

    curr_path = nil

    sf.current_user_role_names.each do |role_name|
      curr_path = NfsStore::Manage::Filesystem.nfs_store_path role_name, sf.container, sf.path, sf.file_name
      if File.exist?(curr_path)
        break
      end
    end

    expect(curr_path).to end_with "#{trashdir}/#{delfn}"

    expect(NfsStore::Upload.hash_for_file(curr_path)).to eq u.file_hash

    non_trash_sf = @container.stored_files

    expect(non_trash_sf.count).to eq 2

    fs = @container.list_fs_files
    expect(fs.length).to eq 2


  end

  it "delete a stored zip file and its exploded archive files" do

    create_filter('.*', role_name: nil)

    orig_count = @container.list_fs_files.length

    upload_file 'test-name-4.txt'
    upload_file 'test-name-5.txt'
    upload_file 'test-name-6.txt'


    # Generate a zip file from the uploaded files
    all_sf = @container.stored_files.order(id: :desc).limit(3)

    all_sf_dl = all_sf.map {|sf| {
        id: sf.id,
        container_id: @container.id,
        retrieval_type: :stored_file,
        activity_log_type: 'activity_log__player_contact_phone',
        activity_log_id: @activity_log.id

      }
    }

    download = NfsStore::Download.new multiple_items: true, container_ids: [@container.id]
    download.current_user = @user
    
    download.retrieve_files_from all_sf_dl

    # Upload the generated zip
    u = upload_file 'test-name.zip', File.read(download.zip_file_path)


    delfn = 'test-name.zip'
    trashdir = '.trash'

    sf = @container.stored_files.where(file_name: delfn).first
    expect(sf).not_to be nil
    expect(sf.file_name).to eq delfn

    sf.move_to_trash!
    expect(sf.path).to eq trashdir

    curr_path = nil

    sf.current_user_role_names.each do |role_name|
      curr_path = NfsStore::Manage::Filesystem.nfs_store_path role_name, sf.container, sf.path, sf.file_name
      if File.exist?(curr_path)
        break
      end
    end

    expect(curr_path).to end_with "#{trashdir}/#{delfn}"
    expect(NfsStore::Upload.hash_for_file(curr_path)).to eq u.file_hash

    non_trash_sf = @container.stored_files
    expect(non_trash_sf.count).to eq 3

    non_trash_af = @container.archived_files
    expect(non_trash_af.count).to eq 0

    fs = @container.list_fs_files
    expect(fs.length).to eq 3 + orig_count

  end

end
