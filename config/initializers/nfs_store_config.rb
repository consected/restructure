# frozen_string_literal: true

ActiveSupport.on_load(:nfs_store_config) do
  self.group_id_range = 600..601

  if Rails.env.production? && !ENV['FILESTORE_CONFIG_SKIP']
    self.nfs_store_directory = ENV['FILESTORE_NFS_DIR']
    self.temp_directory = ENV['FILESTORE_TEMP_UPLOADS_DIR']
    self.containers_dirname = ENV['FILESTORE_CONTAINERS_DIRNAME']
    self.use_parent_sub_dir = (ENV['FILESTORE_USE_PARENT_SUB_DIR'] == 'TRUE')
    FileUtils.mkdir_p temp_directory

    unless Rails.configuration.action_dispatch.x_sendfile_header
      raise FsException::Config, 'action_dispatch.x_sendfile_header not set in production.rb'
    end

  elsif Rails.env.test?
    self.nfs_store_directory = "/var/tmp/nfs_store_test#{ENV['TEST_ENV_NUMBER']}"
    self.temp_directory = "/var/tmp/nfs_store_tmp#{ENV['TEST_ENV_NUMBER']}"
    self.containers_dirname = 'containers'
    FileUtils.mkdir_p temp_directory
    group_id_range.each do |i|
      check_dir = File.join(nfs_store_directory, "#{NfsStore::Manage::Group::NfsMountNamePrefix}#{i}")
      FileUtils.mkdir_p File.join(check_dir) if Rails.env.test?
      FsException::Config.new "Could not access: #{check_dir}" unless File.exist?(check_dir)
    end
  else
    self.nfs_store_directory = '/mnt/fphsfs'
    # Notice the use of /var/tmp rather than /tmp, since we are trying to avoid consuming RAM
    # when uploading and downloading large files
    self.temp_directory = '/var/tmp/nfs_store_tmp'
    self.containers_dirname = 'containers'

    FileUtils.mkdir_p temp_directory
    group_id_range.each do |i|
      check_dir = File.join(nfs_store_directory, "#{NfsStore::Manage::Group::NfsMountNamePrefix}#{i}")
      FileUtils.mkdir_p File.join(check_dir) if Rails.env.test?
      FsException::Config.new "Could not access: #{check_dir}" unless File.exist?(check_dir)
    end
  end

  if nfs_store_directory.blank?
    Rails.logger.info 'NFS Store directory not set. Ignoring the rest of the configuration'
  else

    raise FsException::Config, 'temp_directory not set' if temp_directory.blank?
    raise FsException::Config, 'group_id_range not set' if group_id_range.blank?
    raise FsException::Config, 'containers_dirname not set' if containers_dirname.nil?

    ares = Kernel.system 'which unzip'
    raise FsException::Config, 'unzip not in the path' unless ares

    raise FsException::Config, 'No App Type available' unless Admin::AppType.first

    unless File.exist? temp_directory
      Rails.logger.info 'Making the tmp upload directory'
      FileUtils.mkdir_p temp_directory
    end

  end
end
