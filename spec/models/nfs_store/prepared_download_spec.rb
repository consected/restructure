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

  it 'removes expired worker temp zips without following symlinks or deleting unrelated temp files' do
    old_user_directory = File.join(root, '17')
    fresh_user_directory = File.join(root, '18')
    symlink_user_directory = File.join(root, '19')
    invalid_user_directory = File.join(root, '20')
    [old_user_directory, fresh_user_directory, symlink_user_directory, invalid_user_directory].each do |directory|
      FileUtils.mkdir_p(directory)
    end

    expired_temp = File.join(old_user_directory, "#{download.generate_token}.zip.#{SecureRandom.hex(8)}.tmp")
    File.write(expired_temp, 'partial archive')
    File.utime(2.days.ago.to_time, 2.days.ago.to_time, expired_temp)

    fresh_temp = File.join(fresh_user_directory, "#{download.generate_token}.zip.#{SecureRandom.hex(8)}.tmp")
    File.write(fresh_temp, 'active archive')

    outside_file = File.join(root, 'outside.tmp')
    File.write(outside_file, 'outside')
    symlink_temp = File.join(symlink_user_directory, "#{download.generate_token}.zip.#{SecureRandom.hex(8)}.tmp")
    File.symlink(outside_file, symlink_temp)

    invalid_temp = File.join(invalid_user_directory, "#{'a' * 42}.zip.#{SecureRandom.hex(8)}.tmp")
    File.write(invalid_temp, 'unrecognized temp')
    File.utime(2.days.ago.to_time, 2.days.ago.to_time, invalid_temp)

    download.cleanup!

    expect(File.exist?(expired_temp)).to be false
    expect(Dir.exist?(old_user_directory)).to be false
    expect(File.exist?(fresh_temp)).to be true
    expect(File.symlink?(symlink_temp)).to be true
    expect(File.read(outside_file)).to eq('outside')
    expect(File.exist?(invalid_temp)).to be true
  ensure
    FileUtils.rm_rf(root)
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
