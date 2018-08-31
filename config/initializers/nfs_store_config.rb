ActiveSupport.on_load(:nfs_store_config) do

  self.group_id_range = 600..601

  if Rails.env.production?
    self.nfs_store_directory = ENV['FILESTORE_NFS_DIR']
    self.temp_directory = ENV['FILESTORE_TEMP_UPLOADS_DIR']
    self.containers_dirname = ENV['FILESTORE_CONTAINERS_DIRNAME']
  else
    self.nfs_store_directory = "/mnt/fphsfs"
    # Notice the use of /var/tmp rather than /tmp, since we are trying to avoid consuming RAM
    # when uploading and downloading large files
    self.temp_directory = "/var/tmp/nfs_store_tmp"
    self.containers_dirname = 'containers'

    FileUtils.mkdir_p self.temp_directory
    self.group_id_range.each do |i|
      check_dir = File.join(self.nfs_store_directory, "#{NfsStore::Manage::Group::NfsMountNamePrefix}#{i}")
      FsException::Config.new "Could not access: #{check_dir}" unless File.exist?(check_dir)
    end
  end

  raise FsException::Config.new "nfs_store_directory not set" if self.nfs_store_directory.blank?
  raise FsException::Config.new "temp_directory not set" if self.temp_directory.blank?
  raise FsException::Config.new "group_id_range not set" if self.group_id_range.blank?
  raise FsException::Config.new "containers_dirname not set" if self.containers_dirname.nil?

  ares = Kernel.system 'which archivemount'
  raise FsException::Config.new "archivemount not in the path" unless ares

  raise FsException::Config.new "No App Type available" unless Admin::AppType.first

  unless File.exist? self.temp_directory
    Rails.logger.info "Making the tmp upload directory"
    FileUtils.mkdir_p self.temp_directory
  end
end

raise FsException::Config.new "action_dispatch.x_sendfile_header not set in production.rb" if Rails.env.production? && ! Rails.configuration.action_dispatch.x_sendfile_header

ActiveSupport.on_load(:nfs_store_container) do

  module NfsStore

    module Manage
      class Container < NfsStore::UserBase
        include HandlesUserBase
        include UserHandler
        include NfsStore::OverrideContainer

      end
    end
  end

end

ActiveSupport.on_load(:nfs_store_container_file) do

  module NfsStore

    module Manage
      class ContainerFile < NfsStore::UserBase
        include HandlesUserBase
        include UserHandler
        include NfsStore::OverrideContainerFile

        def master
          container.master
        end

      end
    end
  end


end

ActiveSupport.on_load(:nfs_store_container_list_controller) do

  module NfsStore
    class ContainerListController < NfsStoreController
      include ModelNaming
      include ControllerUtils
      include AppExceptionHandler
      include UserActionLogging
      include MasterHandler
      include NfsStore::OverrideContainerListController
    end
  end

end
