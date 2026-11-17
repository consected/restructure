# frozen_string_literal: true

# Purpose: verify prepared-download token safety, per-user storage, expiry, and cleanup.
require 'rails_helper'

RSpec.describe NfsStore::PreparedDownload, type: :model do
  let(:root) { Rails.root.join('tmp', "prepared-download-spec-#{SecureRandom.hex}").to_s }
  let(:download) { described_class.new(root:) }

  before { allow(NfsStore::Manage::Filesystem).to receive(:temp_directory).and_return(root) }
  after { FileUtils.rm_rf(root) }

  it 'creates a strict url-safe token and scopes its path to the user directory' do
    token = download.generate_token
    expect(token).to match(/\A[A-Za-z0-9_-]{43}\z/)
    expect(download.path_for(user_id: 17, token:)).to eq(File.join(root, '17', "#{token}.zip"))
    expect(download).not_to be_valid_token('../outside')
  end

  it 'recognizes expired downloads and removes expired files and empty user directories' do
    token = download.generate_token
    path = download.path_for(user_id: 17, token:)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, 'archive')
    File.utime(2.days.ago.to_time, 2.days.ago.to_time, path)
    old_sync_zip = File.join(root, 'nfs_store_download_zipfile-old.zip')
    File.write(old_sync_zip, 'old')
    File.utime(2.days.ago.to_time, 2.days.ago.to_time, old_sync_zip)

    expect(download).to be_expired(path)
    download.cleanup!
    expect(File.exist?(path)).to be false
    expect(File.exist?(old_sync_zip)).to be false
    expect(Dir.exist?(File.dirname(path))).to be false
  end
end
