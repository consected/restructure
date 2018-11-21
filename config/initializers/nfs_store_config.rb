ActiveSupport.on_load(:nfs_store_config) do

  self.group_id_range = 600..601

  if Rails.env.production?
    self.nfs_store_directory = ENV['FILESTORE_NFS_DIR']
    self.temp_directory = ENV['FILESTORE_TEMP_UPLOADS_DIR']
    self.containers_dirname = ENV['FILESTORE_CONTAINERS_DIRNAME']
    self.use_parent_sub_dir = (ENV['FILESTORE_USE_PARENT_SUB_DIR'] == 'TRUE')
  else
    self.nfs_store_directory = "/mnt/fphsfs"
    self.nfs_store_directory = "/var/tmp/nfs_store_test" if Rails.env.test?
    # Notice the use of /var/tmp rather than /tmp, since we are trying to avoid consuming RAM
    # when uploading and downloading large files
    self.temp_directory = "/var/tmp/nfs_store_tmp"
    self.containers_dirname = 'containers'

    FileUtils.mkdir_p self.temp_directory
    self.group_id_range.each do |i|
      check_dir = File.join(self.nfs_store_directory, "#{NfsStore::Manage::Group::NfsMountNamePrefix}#{i}")
      FileUtils.mkdir_p File.join(check_dir) if Rails.env.test?
      FsException::Config.new "Could not access: #{check_dir}" unless File.exist?(check_dir)
    end
  end

  if self.nfs_store_directory.blank?
    Rails.logger.info "NFS Store directory not set. Ignoring the rest of the configuration"
  else

    raise FsException::Config.new "temp_directory not set" if self.temp_directory.blank?
    raise FsException::Config.new "group_id_range not set" if self.group_id_range.blank?
    raise FsException::Config.new "containers_dirname not set" if self.containers_dirname.nil?

    ares = Kernel.system 'which unzip'
    raise FsException::Config.new "unzip not in the path" unless ares

    raise FsException::Config.new "No App Type available" unless Admin::AppType.first

    unless File.exist? self.temp_directory
      Rails.logger.info "Making the tmp upload directory"
      FileUtils.mkdir_p self.temp_directory
    end

    raise FsException::Config.new "action_dispatch.x_sendfile_header not set in production.rb" if Rails.env.production? && ! Rails.configuration.action_dispatch.x_sendfile_header
  end
end
