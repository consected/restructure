# frozen_string_literal: true

require 'securerandom'

module NfsStore
  # Encapsulates prepared archive paths, token validation, expiry, and cleanup.
  class PreparedDownload
    TokenPattern = /\A[A-Za-z0-9_-]{43}\z/

    def initialize(root: nil, ttl_hours: Settings::NfsStorePreparedDownloadsTtlHours)
      @root = root || Settings.nfs_store_prepared_downloads_dir
      @root = File.expand_path(@root)
      @ttl_hours = ttl_hours.to_i
    end

    def generate_token
      SecureRandom.urlsafe_base64(32)
    end

    def valid_token?(token)
      TokenPattern.match?(token.to_s)
    end

    def path_for(user_id:, token:)
      raise ArgumentError, 'Invalid prepared download token' unless valid_token?(token)
      raise ArgumentError, 'Invalid user id' unless user_id.to_s.match?(/\A[1-9]\d*\z/)

      File.join(@root, user_id.to_s, "#{token}.zip")
    end

    def available_path(user_id:, token:, now: Time.current)
      return unless valid_token?(token)

      path = path_for(user_id:, token:)
      user_directory = File.lstat(File.dirname(path))
      return if user_directory.symlink? || !user_directory.directory?

      stat = File.lstat(path)
      return if stat.symlink? || !stat.file? || expired?(path, now:)

      path
    rescue Errno::ENOENT, ArgumentError
      nil
    end

    def expired?(path, now: Time.current)
      stat = File.lstat(path)
      !stat.file? || stat.mtime < expiry_time(now:)
    rescue Errno::ENOENT
      true
    end

    def expiry_time(now: Time.current)
      now - @ttl_hours.hours
    end

    def cleanup!(now: Time.current)
      cutoff = expiry_time(now:)
      Dir.glob(File.join(@root, '*', '*.zip')).each do |path|
        user_directory = File.dirname(path)
        next unless File.basename(path, '.zip').match?(TokenPattern)

        directory_stat = File.lstat(user_directory)
        file_stat = File.lstat(path)
        next if directory_stat.symlink? || file_stat.symlink?
        next unless file_stat.file? && file_stat.mtime < cutoff

        FileUtils.rm_f(path)
      rescue Errno::ENOENT
        next
      end
      remove_empty_user_directories
      remove_expired_temporary_archives(cutoff)
    end

    private

    def remove_empty_user_directories
      Dir.glob(File.join(@root, '*')).each do |directory|
        next unless File.directory?(directory) && File.basename(directory).match?(/\A\d+\z/)
        next if File.lstat(directory).symlink?
        next unless Dir.empty?(directory)

        Dir.rmdir(directory)
      rescue Errno::ENOENT, Errno::ENOTEMPTY
        next
      end
    end

    def remove_expired_temporary_archives(cutoff)
      temp_directory = NfsStore::Manage::Filesystem.temp_directory
      Dir.glob(File.join(temp_directory, "#{NfsStore::Archive::ZipFileGenerator::ZipTempFilePrefix}*")).each do |path|
        stat = File.lstat(path)
        next if stat.symlink?
        next unless stat.file? && stat.mtime < cutoff

        FileUtils.rm_f(path)
      rescue Errno::ENOENT
        next
      end
    end
  end
end
