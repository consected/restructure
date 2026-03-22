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
      # Allow real Pathname calls to proceed
      allow(Pathname).to receive(:new).and_call_original

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
  end

  describe '#nfs_source_filesystem_status' do
    it 'returns source filesystem status with mount information - Issue896' do
      si = Admin::ServerInfo.new(@admin)
      result = si.nfs_source_filesystem_status

      expect(result).to be_a(Hash)
      expect(result).to have_key(:source_filesystem)
      expect(result).to have_key(:status)

      # Status should be one of the valid values
      expect(result[:status]).to be_in(%i[mounted failed not_configured error])
    end

    it 'checks if first gid directory is a mountpoint - Issue896' do
      si = Admin::ServerInfo.new(@admin)
      nfs_dir = NfsStore::Manage::Filesystem.nfs_store_directory
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(nfs_dir, "gid#{first_gid}")

      # Mock the first gid directory as a mountpoint
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        allow(pn).to receive(:mountpoint?).and_return(true) if path == first_mount_path
        pn
      end

      result = si.nfs_source_filesystem_status
      expect(result[:status]).to eq(:mounted)
    end

    it 'extracts source filesystem path from mount command output - Issue896' do
      si = Admin::ServerInfo.new(@admin)
      nfs_dir = NfsStore::Manage::Filesystem.nfs_store_directory
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(nfs_dir, "gid#{first_gid}")

      # Mock mount output with actual gid directory mount (as shown in real mount output)
      mock_mount_output = "/media/test/nfs_store/main on #{first_mount_path} type fuse (rw,nosuid)\n"
      allow(si).to receive(:get_mount_output).and_return(mock_mount_output)

      result = si.nfs_source_filesystem_status

      # Should extract the source filesystem path (first part before ' on ')
      expect(result[:source_filesystem]).to eq('/media/test/nfs_store/main')
    end

    it 'handles missing mount command gracefully - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock the mount command to fail
      allow(si).to receive(:get_mount_output).and_raise(Errno::ENOENT, 'mount command not found')

      result = si.nfs_source_filesystem_status

      # Should still return a result
      expect(result).to be_a(Hash)
      expect(result[:status]).to eq(:error)
    end
  end

  describe '#nfs_store_mount_dirs' do
    it 'identifies failed mountpoints correctly - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock one mountpoint as failed
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Allow real Pathname for all paths
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        if path == first_mount_path
          # Mock the mountpoint? method to return false for this specific path
          allow(pn).to receive(:mountpoint?).and_return(false)
        end
        pn
      end

      result = si.nfs_store_mount_dirs

      # Should have at least one failed mountpoint
      failed_mounts = result.select { |m| [:failed, false].include?(m[:mountpoint_status]) }
      expect(failed_mounts).not_to be_empty
    end

    it 'identifies inaccessible directories correctly - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock one directory as inaccessible
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Allow Dir.entries to work normally, except for the first mount path
      original_dir_entries = Dir.method(:entries)
      allow(Dir).to receive(:entries) do |path|
        raise Errno::EACCES, 'Permission denied' if path == first_mount_path

        original_dir_entries.call(path)
      end

      result = si.nfs_store_mount_dirs

      # Should have at least one failed directory status
      failed_dirs = result.select { |m| [:failed, false].include?(m[:directory_status]) }
      expect(failed_dirs).not_to be_empty
    end
  end

  describe '#nfs_store_mount_dirs edge cases' do
    it 'handles partial mountpoint failures (mixed healthy and failed) - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      # Assume we have at least 2 group IDs
      return skip('Need at least 2 group IDs for this test') if group_id_range.count < 2

      first_gid = group_id_range.first
      second_gid = group_id_range.to_a[1]
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Mock first mountpoint as failed, others as healthy
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        if path == first_mount_path
          allow(pn).to receive(:mountpoint?).and_return(false)
        elsif path.include?('/gid')
          allow(pn).to receive(:mountpoint?).and_return(true)
        end
        pn
      end

      result = si.nfs_store_mount_dirs

      # Should have exactly one failed mountpoint
      failed_mounts = result.select { |m| m[:mountpoint_status] == :failed }
      healthy_mounts = result.select { |m| m[:mountpoint_status] == :mounted }

      expect(failed_mounts.length).to eq(1)
      expect(healthy_mounts.length).to eq(group_id_range.count - 1)
      expect(failed_mounts.first[:group_id]).to eq(first_gid)
    end

    it 'handles empty or blank NFS store directory - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock blank directory
      allow(NfsStore::Manage::Filesystem).to receive(:nfs_store_directory).and_return(nil)

      result = si.nfs_store_mount_dirs

      # Should return empty array when directory is not configured
      expect(result).to eq([])
    end

    it 'handles malformed mount output gracefully - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock malformed mount output
      malformed_output = "random text\nno proper format\n"
      allow(si).to receive(:get_mount_output).and_return(malformed_output)

      result = si.nfs_store_mount_dirs

      # Should still return results, but source_filesystem will be nil
      expect(result).to be_an(Array)
      expect(result).not_to be_empty
      result.each do |mount_info|
        expect(mount_info[:source_filesystem]).to be_nil
      end
    end

    it 'returns consistent data structure even on exceptions - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock multiple failures
      allow(si).to receive(:get_mount_output).and_raise(StandardError, 'Unexpected error')
      allow(Pathname).to receive(:new).and_raise(StandardError, 'Path error')

      result = si.nfs_store_mount_dirs

      # Should return empty array on major failure, not raise exception
      expect(result).to eq([])
    end

    it 'handles very long mount output efficiently - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Generate large mount output (simulating system with many mounts)
      large_mount_output = (1..1000).map do |i|
        "/dev/mapper/vg#{i} on /mnt/volume#{i} type ext4 (rw)"
      end.join("\n")

      allow(si).to receive(:get_mount_output).and_return(large_mount_output)

      # Should complete without timeout or excessive memory usage
      expect { si.nfs_store_mount_dirs }.not_to raise_error
      result = si.nfs_store_mount_dirs

      expect(result).to be_an(Array)
    end

    it 'correctly identifies mountpoints vs regular directories - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Explicitly check that mountpoint? is being called
      original_pathname_new = Pathname.method(:new)
      pathname_spy = nil
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        if path == first_mount_path
          pathname_spy = instance_spy(Pathname)
          allow(pathname_spy).to receive(:mountpoint?).and_return(true)
          pathname_spy
        else
          pn
        end
      end

      si.nfs_store_mount_dirs

      # Verify mountpoint? was actually called (not just directory existence check)
      expect(pathname_spy).to have_received(:mountpoint?)
    end

    it 'reports directory access errors with specific error types - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Test different error types
      [Errno::EACCES, Errno::ENOENT, Errno::EIO].each do |error_class|
        # Only stub the specific path we're testing
        allow(Dir).to receive(:entries).and_call_original
        allow(Dir).to receive(:entries).with(first_mount_path).and_raise(error_class, "Test error: #{error_class}")

        result = si.nfs_store_mount_dirs
        failed_dir = result.find { |m| m[:mount_path] == first_mount_path }

        expect(failed_dir[:directory_status]).to eq(:failed)
      end
    end
  end

  describe '#configuration_failed_reason' do
    it 'includes failed mountpoints in configuration failures - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock a mountpoint failure
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Allow real Pathname for all paths
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        allow(pn).to receive(:mountpoint?).and_return(false) if path == first_mount_path
        pn
      end

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

      # First, ensure the mountpoint check succeeds so we get to the directory check
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        allow(pn).to receive(:mountpoint?).and_return(true) if path == first_mount_path
        pn
      end

      # Then make the directory check fail
      original_dir_entries = Dir.method(:entries)
      allow(Dir).to receive(:entries) do |path|
        raise Errno::EACCES, 'Permission denied' if path == first_mount_path

        original_dir_entries.call(path)
      end

      # Get configuration failures
      failures = si.configuration_failed_reason

      # Should include a message about the inaccessible directory
      expect(failures).to be_an(Array)
      failed_dir_message = failures.find { |msg| msg.include?('directory') && msg.include?('accessible') }
      expect(failed_dir_message).to be_present
    end

    it 'does not include failures when all mountpoints are healthy - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock all mountpoints as healthy
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        # Mock all gid paths as mountpoints
        allow(pn).to receive(:mountpoint?).and_return(true) if path.include?('/gid')
        pn
      end

      # Get configuration failures
      failures = si.configuration_failed_reason

      # Should not include NFS mountpoint-related failures
      # Filter for only NFS/mountpoint related messages
      mountpoint_failures = failures.select { |msg| msg.include?('mountpoint') && msg.include?('gid') }
      expect(mountpoint_failures).to be_empty
    end

    it 'prioritizes mountpoint failures over directory failures in error messages - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Mock mountpoint failure (directory check won't happen if mountpoint fails)
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        allow(pn).to receive(:mountpoint?).and_return(false) if path == first_mount_path
        pn
      end

      failures = si.configuration_failed_reason

      # Should have mountpoint failure message
      mountpoint_failure = failures.find { |msg| msg.include?('mountpoint') && msg.include?(first_mount_path) }
      expect(mountpoint_failure).to be_present

      # Should not have directory failure for the same path
      directory_failure = failures.find { |msg| msg.include?('directory') && msg.include?(first_mount_path) }
      expect(directory_failure).to be_nil
    end

    it 'reports each failed mountpoint separately in configuration failures - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      return skip('Need at least 2 group IDs for this test') if group_id_range.count < 2

      # Mock multiple mountpoint failures
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        allow(pn).to receive(:mountpoint?).and_return(false) if path.include?('/gid')
        pn
      end

      failures = si.configuration_failed_reason

      # Should have separate failure message for each group ID
      mountpoint_failures = failures.select { |msg| msg.include?('mountpoint') && msg.include?('gid') }
      expect(mountpoint_failures.length).to eq(group_id_range.count)

      # Each group ID should be mentioned
      group_id_range.each do |gid|
        expect(mountpoint_failures.any? { |msg| msg.include?("gid#{gid}") }).to be true
      end
    end

    it 'includes helpful link to NfsStore Settings in failure messages - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Mock a mountpoint failure
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        allow(pn).to receive(:mountpoint?).and_return(false) if path == first_mount_path
        pn
      end

      failures = si.configuration_failed_reason

      # Mountpoint-specific failures should mention NfsStore Settings
      mountpoint_failures = failures.select { |msg| msg.include?('mountpoint') || msg.include?('directory') }
      expect(mountpoint_failures).not_to be_empty
      mountpoint_failures.each do |failure|
        expect(failure).to include('NfsStore Settings')
      end
    end

    it 'combines NFS failures with other configuration failures - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Mock both NFS failure and other configuration failure
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        allow(pn).to receive(:mountpoint?).and_return(false) if path == first_mount_path
        pn
      end

      # Mock additional configuration failure (e.g., from NfsStore::Manage::Filesystem)
      allow(NfsStore::Manage::Filesystem).to receive(:configuration_successful).and_return(false)
      allow(NfsStore::Manage::Filesystem).to receive(:configuration_failed_reason).and_return(['Some other NFS config issue'])

      failures = si.configuration_failed_reason

      # Should include both types of failures
      expect(failures.any? { |msg| msg.include?('mountpoint') }).to be true
      expect(failures.any? { |msg| msg.include?('other NFS config') }).to be true
      expect(failures.length).to be >= 2
    end

    it 'caches configuration_failed_reason to avoid redundant checks - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      # Call once
      first_result = si.configuration_failed_reason

      # Mock should only be called once for the mountpoint check
      expect(si).not_to receive(:nfs_store_mount_dirs)

      # Call again
      second_result = si.configuration_failed_reason

      # Should return cached result
      expect(second_result).to equal(first_result)
    end

    it 'formats failure messages consistently with group ID and path - Issue896' do
      si = Admin::ServerInfo.new(@admin)

      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      first_gid = group_id_range.first
      first_mount_path = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "gid#{first_gid}")

      # Mock a mountpoint failure
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        allow(pn).to receive(:mountpoint?).and_return(false) if path == first_mount_path
        pn
      end

      failures = si.configuration_failed_reason
      mountpoint_failure = failures.find { |msg| msg.include?('mountpoint') }

      # Should include both the full path and the gid in parentheses
      expect(mountpoint_failure).to include(first_mount_path)
      expect(mountpoint_failure).to include("(gid#{first_gid})")
    end
  end
end
