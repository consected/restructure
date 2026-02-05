# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ServerInfo, type: :model do
  include MasterSupport

  before :example do
    create_admin
  end

  it 'requires an active admin user' do
    expect { Admin::ServerInfo.new(@admin) }.not_to raise_error

    expect do
      Admin::ServerInfo.new(nil)
    end.to raise_error(FphsException, 'Initialization with admin blank is not valid')
  end

  it 'gets a list of server settings' do
    si = Admin::ServerInfo.new(@admin)

    as = si.app_settings
    expect(as).to be_a Hash
    expect(as).not_to be_empty

    expect(as['DefaultMigrationSchema']).to eq 'ml_app'
  end

  it 'gets a list of database settings' do
    si = Admin::ServerInfo.new(@admin)

    as = si.db_settings
    expect(as).to be_a Hash
    expect(as).not_to be_empty

    expect(as[:connection][:adapter]).to eq 'postgresql'
  end

  it 'gets the database server version' do
    si = Admin::ServerInfo.new(@admin)

    version = si.db_version
    expect(version).to be_a String
    expect(version).to include('PostgreSQL')
  end

  it 'gets memcached connection stats' do
    si = Admin::ServerInfo.new(@admin)

    stats = si.memcached_stats
    expect(stats).to be_a Hash
    expect(stats[:status]).to be_present

    # Should return either 'connected', 'not configured', or 'connection failed'
    expect(stats[:status]).to match(/connected|not configured|connection failed/)

    # If connected, should have servers
    if stats[:status] == 'connected'
      expect(stats[:servers]).to be_present
    # If not configured, should have details
    elsif stats[:status] == 'not configured'
      expect(stats[:details]).to be_present
    # If connection failed, should have error message
    elsif stats[:status] == 'connection failed'
      expect(stats[:error]).to be_present
    end
  end

  it 'handles database connection errors gracefully' do
    si = Admin::ServerInfo.new(@admin)

    # Mock connection error
    allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, 'Connection failed')

    version = si.db_version
    expect(version).to include('not available')
    expect(version).to include('Connection failed')
  end

  it 'handles memcached connection errors gracefully' do
    si = Admin::ServerInfo.new(@admin)

    # Mock a MemCacheStore instance
    mock_cache = instance_double(ActiveSupport::Cache::MemCacheStore)
    allow(Rails).to receive(:cache).and_return(mock_cache)
    allow(mock_cache).to receive(:is_a?).with(ActiveSupport::Cache::MemCacheStore).and_return(true)
    allow(mock_cache).to receive(:stats).and_raise(StandardError, 'Memcached unavailable')

    stats = si.memcached_stats
    expect(stats[:status]).to eq('connection failed')
    expect(stats[:error]).to include('Memcached unavailable')
  end

  # Tests for issue #896 - NFS mountpoint info
  describe '#nfs_store_mount_dirs' do
    it 'returns structured data with mountpoint status for all group IDs - Issue896' do
      si = Admin::ServerInfo.new(@admin)
      result = si.nfs_store_mount_dirs

      # Should return an array of mountpoint info
      expect(result).to be_an(Array)
      expect(result).not_to be_empty

      # Should have info for each group_id in the range
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      expect(result.length).to eq(group_id_range.count)

      # Each entry should be a hash with required fields
      result.each do |mount_info|
        expect(mount_info).to be_a(Hash)
        expect(mount_info).to have_key(:group_id)
        expect(mount_info).to have_key(:mount_path)
        expect(mount_info).to have_key(:source_filesystem)
        expect(mount_info).to have_key(:mountpoint_status)
        expect(mount_info).to have_key(:directory_status)

        # Status values should be boolean or symbol
        expect(mount_info[:mountpoint_status]).to be_in([:mounted, :failed, true, false])
        expect(mount_info[:directory_status]).to be_in([:accessible, :failed, true, false])
      end
    end

    it 'uses Ruby Pathname methods instead of shell commands for mountpoint checks - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Ensure IO.popen is NOT called for mountpoint checks
      expect(IO).not_to receive(:popen).with(/mountpoint/)

      # The method should use Pathname#mountpoint? instead
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      group_id_range.each do |gid|
        mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{gid}")
        pathname = Pathname.new(mount_path)
        allow(Pathname).to receive(:new).with(mount_path).and_return(pathname)
        allow(pathname).to receive(:mountpoint?).and_return(true)
      end

      result = si.nfs_store_mount_dirs
      expect(result).to be_an(Array)
    end

    it 'checks directory listing accessibility using Ruby Dir methods - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Should use Dir.entries or similar Ruby methods, not shell ls commands
      expect(IO).not_to receive(:popen).with(/\bls\b/)

      result = si.nfs_store_mount_dirs
      expect(result).to be_an(Array)

      # Each entry should have directory_status checked
      result.each do |mount_info|
        expect(mount_info[:directory_status]).to be_present
      end
    end

    it 'extracts source filesystem path from mount command output - Issue896' do
      si = Admin::ServerInfo.new(@admin)
      result = si.nfs_store_mount_dirs

      # At least one entry should have a source_filesystem
      expect(result.any? { |m| m[:source_filesystem].present? }).to be true

      # Source filesystem should be a path-like string
      result.each do |mount_info|
        if mount_info[:source_filesystem].present?
          # Should look like a filesystem path (e.g., /efs-prod/main, /var/tmp/nfs_store)
          expect(mount_info[:source_filesystem]).to match(%r{^/[\w\-/]+})
        end
      end
    end

    it 'identifies failed mountpoints correctly - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock one mountpoint as failed
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Mock Pathname to return false for mountpoint check
      pathname = instance_double(Pathname)
      allow(Pathname).to receive(:new).with(first_mount_path).and_return(pathname)
      allow(pathname).to receive(:mountpoint?).and_return(false)
      allow(pathname).to receive(:to_s).and_return(first_mount_path)

      result = si.nfs_store_mount_dirs

      # Should have at least one failed mountpoint
      failed_mounts = result.select { |m| m[:mountpoint_status] == :failed || m[:mountpoint_status] == false }
      expect(failed_mounts).not_to be_empty
    end

    it 'identifies inaccessible directories correctly - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock one directory as inaccessible
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Mock Dir.entries to raise an error
      allow(Dir).to receive(:entries).with(first_mount_path).and_raise(Errno::EACCES, 'Permission denied')

      result = si.nfs_store_mount_dirs

      # Should have at least one failed directory status
      failed_dirs = result.select { |m| m[:directory_status] == :failed || m[:directory_status] == false }
      expect(failed_dirs).not_to be_empty
    end

    it 'handles missing mount command gracefully - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock the mount command to fail
      allow(si).to receive(:`).with(/mount/).and_raise(Errno::ENOENT, 'mount command not found')

      result = si.nfs_store_mount_dirs

      # Should still return results, possibly with empty source_filesystem
      expect(result).to be_an(Array)
      expect(result).not_to be_empty
    end
  end

  describe '#configuration_failed_reason' do
    it 'includes failed mountpoints in configuration failures - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock a mountpoint failure
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      pathname = instance_double(Pathname)
      allow(Pathname).to receive(:new).with(first_mount_path).and_return(pathname)
      allow(pathname).to receive(:mountpoint?).and_return(false)
      allow(pathname).to receive(:to_s).and_return(first_mount_path)

      # Get configuration failures
      failures = si.configuration_failed_reason

      # Should include a message about the failed mountpoint
      expect(failures).to be_an(Array)
      failed_mount_message = failures.find { |msg| msg.include?('mountpoint') || msg.include?('gid') }
      expect(failed_mount_message).to be_present
    end

    it 'includes inaccessible directories in configuration failures - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock a directory access failure
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      allow(Dir).to receive(:entries).with(first_mount_path).and_raise(Errno::EACCES, 'Permission denied')

      # Get configuration failures
      failures = si.configuration_failed_reason

      # Should include a message about the inaccessible directory
      expect(failures).to be_an(Array)
      failed_dir_message = failures.find { |msg| msg.include?('directory') || msg.include?('access') }
      expect(failed_dir_message).to be_present
    end

    it 'does not include failures when all mountpoints are healthy - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock all mountpoints as healthy
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      group_id_range.each do |gid|
        mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{gid}")
        pathname = instance_double(Pathname)
        allow(Pathname).to receive(:new).with(mount_path).and_return(pathname)
        allow(pathname).to receive(:mountpoint?).and_return(true)
        allow(Dir).to receive(:entries).with(mount_path).and_return(['.', '..', 'app-type-1'])
      end

      # Get configuration failures
      failures = si.configuration_failed_reason

      # Should not include mountpoint-related failures
      mountpoint_failures = failures.select { |msg| msg.include?('mountpoint') || msg.include?('NFS') }
      expect(mountpoint_failures).to be_empty
    end
  end
end
