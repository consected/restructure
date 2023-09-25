# frozen_string_literal: true

ActiveSupport.on_load(:nfs_store_config) do
  max_group_id = ENV['FILESTORE_MAX_GRP_ID']
  max_group_id = max_group_id ? max_group_id.to_i : 601
  self.group_id_range = 600..max_group_id

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
    self.use_parent_sub_dir = (ENV['FILESTORE_USE_PARENT_SUB_DIR'] == 'TRUE')

    FileUtils.mkdir_p temp_directory
    group_id_range.each do |i|
      check_dir = File.join(nfs_store_directory, "#{NfsStore::Manage::Group::NfsMountNamePrefix}#{i}")
      FileUtils.mkdir_p File.join(check_dir) if Rails.env.test?
      FsException::Config.new "Could not access: #{check_dir}" unless File.exist?(check_dir)
    end
  end

  self.configuration_failed_reason = []

  if nfs_store_directory.blank?
    Rails.logger.info 'NFS Store directory not set. Ignoring the rest of the configuration'
  else
    configuration_failed_reason << 'temp_directory not set' if temp_directory.blank?
    configuration_failed_reason << 'group_id_range not set' if group_id_range.blank?
    configuration_failed_reason << 'containers_dirname not set' if containers_dirname.nil?

    ares = Kernel.system 'which unzip'
    configuration_failed_reason << 'unzip not in the path' unless ares

    app_type = Admin::AppType.active_app_types.first
    if app_type
      unless NfsStore::Manage::Filesystem.app_type_containers_path_exists?(app_type.id)
        configuration_failed_reason << "App Type filesystem not configured (#{app_type.id}), or NFS not set up"
      end
    else
      configuration_failed_reason << 'No App Type available'
    end
  end

  self.configuration_successful = configuration_failed_reason.blank?
end
