# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe NfsStore::Download, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def default_role
    'file1'
  end

  before :example do
    @other_users = []
    @other_users << create_user.first
    @other_users << create_user.first
    @other_users << create_user.first

    setup_nfs_store
    setup_container_and_al
    setup_default_filters
  end

  it 'finds a download using a path rather than an id' do
    file_name = 'test-path-download.txt'
    upload_file file_name, 'text content'

    expect(@container.stored_files.last.file_name).to eq file_name

    download_path = file_name
    res = NfsStore::Download.find_download_by_path(@container, download_path)
    expect(res).to be_a NfsStore::Manage::StoredFile
    expect(res.retrieval_type).to eq :stored_file
    expect(res.id).to eq @container.stored_files.last.id
  end

  # Regression coverage for issue #1553: a single selected file is sent directly rather than zipped.
  describe 'selected items retrieval (issue #1553)' do
    def selected_item_for(file_name)
      stored_file = @container.stored_files.find_by(file_name:)
      { id: stored_file.id, retrieval_type: :stored_file, container_id: @container.id,
        activity_log_type: nil, activity_log_id: 0 }
    end

    def new_download
      NfsStore::Download.new container: @container, activity_log: @activity_log, multiple_items: true
    end

    it 'exposes the original path and name of a single selected file, without creating a zip' do
      upload_file 'single-download.txt', 'single file content'
      download = new_download

      download.retrieve_files_from [selected_item_for('single-download.txt')]

      expect(download.zip_file_path).to be_nil
      expect(download.single_file_name).to eq 'single-download.txt'
      expect(File.read(download.single_file_path)).to eq 'single file content'
    end

    it 'still zips multiple selected files with their original file names' do
      upload_file 'multi-a.txt', 'content a'
      upload_file 'multi-b.txt', 'content b'
      download = new_download

      download.retrieve_files_from [selected_item_for('multi-a.txt'), selected_item_for('multi-b.txt')]

      expect(download.single_file_path).to be_nil
      expect(download.single_file_name).to be_nil
      entry_names = Zip::File.open(download.zip_file_path.path) { |zip| zip.map(&:name) }
      expect(entry_names.map { |n| File.basename(n) }).to contain_exactly('multi-a.txt', 'multi-b.txt')
    end

    it 'does not return a single file that is a symbolic link' do
      upload_file 'linked-download.txt', 'legitimate content'
      stored_file = @container.stored_files.find_by(file_name: 'linked-download.txt')
      retrieval_path = stored_file.retrieval_path
      secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
      File.write(secret_path, 'unauthorized secret content')

      begin
        File.delete(retrieval_path)
        File.symlink(secret_path, retrieval_path)

        expect { new_download.retrieve_files_from [selected_item_for('linked-download.txt')] }
          .to raise_error(FsException::SymlinkBlocked, /symbolic link/)
      ensure
        FileUtils.rm_f secret_path
      end
    end
  end
end
