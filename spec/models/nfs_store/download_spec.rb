# frozen_string_literal: true

# Purpose: verify filestore download retrieval, direct single-file delivery, and background threshold assessment.
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

  # Regression coverage for issue #1568: files extracted from a zip archive must be found by their download path
  # so that previewing them (for example DICOM files in nested folders) does not return Not Found.
  describe 'archived file download paths (issue #1568)' do
    def upload_zip_with_nested_file(zip_name, relative_file)
      Dir.mktmpdir do |src|
        FileUtils.mkdir_p File.join(src, File.dirname(relative_file))
        File.write File.join(src, relative_file), 'archived content'
        zip_path = File.join(src, zip_name)
        Dir.chdir(src) { expect(Kernel.system('zip', '-r', zip_path, File.dirname(relative_file))).to be_truthy }
        upload_file zip_name, File.binread(zip_path)
      end
    end

    it 'finds an archived file in a folder directly inside the archive by its download path' do
      upload_zip_with_nested_file 'study.zip', 'series1/image.dcm'

      res = NfsStore::Download.find_download_by_path(@container, 'study.zip/series1/image.dcm')
      expect(res).to be_a NfsStore::Manage::ArchivedFile
      expect(res.file_name).to eq 'image.dcm'
    end

    it 'finds an archived file nested more than one folder deep by its download path' do
      upload_zip_with_nested_file 'study-deep.zip', 'patient1/study2/series3/image.dcm'

      res = NfsStore::Download.find_download_by_path(@container, 'study-deep.zip/patient1/study2/series3/image.dcm')
      expect(res).to be_a NfsStore::Manage::ArchivedFile
      expect(res.file_name).to eq 'image.dcm'
      expect(res.path).to eq 'patient1/study2/series3'
    end

    it 'returns nil for a path made only of slashes' do
      expect(NfsStore::Download.find_download_by_path(@container, '/')).to be_nil
      expect(NfsStore::Download.find_download_by_path(@container, '//')).to be_nil
    end
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

  describe '#background_required?' do
    it 'requires a background download above either configured threshold, but not at the boundary' do
      allow(NfsStore::Download).to receive(:background_download_max_files).and_return(2)
      allow(NfsStore::Download).to receive(:background_download_max_bytes).and_return(20)
      download = described_class.new

      download.all_action_items = [{ file_size: 10 }, { file_size: 10 }]
      expect(download).not_to be_background_required

      download.all_action_items = [{ file_size: 10 }, { file_size: 11 }]
      expect(download).to be_background_required

      download.all_action_items = [{ file_size: 1 }, { file_size: 1 }, { file_size: 1 }]
      expect(download).to be_background_required

      allow(NfsStore::Download).to receive(:background_download_max_files).and_return(100)
      download.all_action_items = [{ file_size: 21 }]
      expect(download).not_to be_background_required
    end
  end
end
