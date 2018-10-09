module NfsStore
  module Manage
    class Filesystem

      # Setting FinalFilePerms to nil prevents a change to the file permissions
      FinalFilePerms = nil #0440
      AppDirprefix = 'app-type-'

      def self.temp_directory= dir
        @temp_directory = dir
      end

      def self.temp_directory
        @temp_directory
      end

      def self.nfs_store_directory= dir
        @nfs_store_directory = dir
      end

      def self.nfs_store_directory
        @nfs_store_directory
      end


      def self.group_id_range= r
        @group_id_range = r
      end

      def self.group_id_range
        @group_id_range
      end

      def self.containers_dirname= name
        @containers_dirname = name
      end

      def self.containers_dirname
        @containers_dirname
      end

      # Path to the 'containers' directory for the specified app type within the
      # mount point for the specified role name
      # @param app_type_id [Integer] ID for the app type
      # @param role_name [String] specific role name to use to find the mount point
      def self.app_type_containers_path app_type_id, role_name
        fs_dir = self.nfs_store_directory
        app_dir = "#{AppDirprefix}#{app_type_id}"
        mount_name = Group.nfs_mount_from_role_name(role_name)
        parts = []
        parts << fs_dir
        parts << mount_name
        parts << app_dir
        parts << self.containers_dirname unless self.containers_dirname.blank?
        File.join parts
      end

      # Get the group ID gid based on the directory ownership of the 'containers' directory
      # in the specified app type
      # @param app_type_id [Integer]
      # @return [Integer] gid or nil
      def self.app_type_containers_gid app_type_id
        Group.valid_role_names.each do |role_name|
          path = nfs_store_path role_name, app_type_id: app_type_id
          Rails.logger.debug "Trying path for app_type_containers_gid: #{path}"
          if Pathname.new(path).readable?
            return File.stat(path).gid
          end
        end
        return
      end

      # Generate the absolute path to the specified item, based on the provided options
      # @param role_name [String]
      # @param app_type_id [Integer] (optional) app type to be used, or if nil rely on the current user's
      #   app type set in the container
      # @param container [NfsStore::Manage::Container] the container, which will also set the app type if it is not set explicitly
      # @param path [String] path relative to the container for a directory
      # @param file_name [String] specific file name to use
      # @return [String] path string
      def self.nfs_store_path role_name, container=nil, path=nil, file_name=nil, app_type_id: nil, strip_final_slash: nil
        fs_dir = self.nfs_store_directory

        # Use the specified app type if stated explicitly, otherwise get it from the container
        app_type_id ||= container&.current_user&.app_type_id
        app_dir = "#{AppDirprefix}#{app_type_id}"
        mount_name = Group.nfs_mount_from_role_name(role_name)
        parts = []
        parts << fs_dir
        parts << mount_name
        parts << app_dir
        parts << self.containers_dirname unless self.containers_dirname.blank?

        # Use the parent_path if the container defines it, to place the container directory in a parent directory
        unless container&.parent_sub_dir.blank?
          psd_parts = container&.parent_sub_dir.split('/').reject(&:blank?)
          parts += psd_parts
        end

        parts << container&.directory_name if container&.directory_name
        parts << path unless path.blank?
        parts << file_name if file_name

        p = File.join(parts)

        if strip_final_slash
          clean_path p
        else
          p
        end
      end

      # Clean up relative paths
      # @param path [String] simple relative path
      # @return [String, nil] cleaned up path, or nil if it represents the root
      def self.clean_path path
        return nil if path.blank? || path == '.'
        path.sub(/\/$/, '')
      end

      # Test permissions on a container (sub)directory
      # @param role_name [String] role name for user
      # @param container [NfsStore::Manage::Container]
      # @param action [Symbol(:write, :mkdir, :read, :exists)] the action to test
      # @param extra_path [String] (optional) relative path to test
      # @param file_name [String] (optional) filename to test
      # @param ok_if_exists [Boolean] (optional) if true don't raise an exception if the mkdir extra_path already exists
      # @return [Boolean] true = allowed
      def self.test_dir role_name, container, action, extra_path: nil, file_name: nil, ok_if_exists: nil
        # Make sure we can write to this directory

        begin
          if action == :write
            fs_test_path = nfs_store_path(role_name, container, extra_path, '.test_file')
            FileUtils.rm fs_test_path if File.exist? fs_test_path
            # Avoid a strange NFS timing issue where touch hits a stale file handle
            # Give rm time to complete cleanly
            (0..9).each do
              break unless File.exist? fs_test_path
              sleep 0.1
            end
            FileUtils.touch fs_test_path
            FileUtils.rm fs_test_path
          elsif action == :mkdir
            fs_test_path = nfs_store_path(role_name, container, extra_path, strip_final_slash: true)
            if File.exist?(fs_test_path)
              if ok_if_exists
                return true
              else
                raise FsException::Action.new "Target to create directory already exists: #{fs_test_path}"
              end
            end

            # If the directory does not already exist, we need to get to the deepest point in the path
            # to see if it is creatable
            # This may be actually higher than the container_path, since container.parent_sub_dir may
            # be a directory that doesn't exist yet
            container_parent = container.path_to_parent_dir_for role_name: role_name

            # Check the path to create is actually part of the container
            container_path = container.path_for role_name: role_name
            unless fs_test_path.start_with? container_path
              Rails.logger.info "Container path is not part of the path to be tested for mkdir"
              return false
            end

            # Calculate the sub_path to be all the components that are deeper than the container_parent
            sub_path = fs_test_path[container_parent.length..-1]
            sub_path_parts = sub_path.split('/').reject(&:blank?)
            curr_path = container_parent

            # If the baseline path already exists then run through the sub-directories until one doesn't exist
            if File.exist? curr_path
              sub_path_parts.each do |sub_dir|
                curr_path = File.join(curr_path, sub_dir)
                break unless File.exist? curr_path
              end
            end

            # Although we tested up front for existence of the directory, use this as a failsafe to
            # ensure that we can not accidentally remove an existing file unexpectedly
            if File.exist? curr_path
              raise FsException::Action.new "Target directory already exists when attempting test: #{fs_test_path}"
            end
            FileUtils.touch curr_path
            FileUtils.rm curr_path
          elsif action == :read
            fs_test_path = nfs_store_path(role_name, container, extra_path, file_name)
            return Pathname.new(fs_test_path).readable?
          elsif  action == :exists
            fs_test_path = nfs_store_path(role_name, container, extra_path, file_name)
            return File.exist? fs_test_path
          else
            raise FsException::Action.new "Unknown way to test a directory: #{action}"
          end

        rescue Errno::EACCES, Errno::ENOENT
          return false
        end

      end

      # Move temporary file to its final location after upload
      # @param role_name [String] current user role
      # @param from_path [String] absolute path to the temporary file to move
      # @param container [NfsStore::Manage::Container] container to move the file into
      # @param path [String] the path within the container to move the file to
      # @param file_name [String] the actual file name to use for the file
      # @return [True] true represents success, exception on failure
      def self.move_file_to_final_location role_name, from_path, container, path, file_name
        fs_path = nfs_store_path(role_name, container, path, file_name)
        raise FsException::Upload.new "File already exists. Will not overwrite: #{file_name} in '#{container.name}'" if File.exist? fs_path

        test_dir role_name, container, :write

        unless path.blank? || test_dir(role_name, container, :exists, extra_path: path)
          mkpath = nfs_store_path(role_name, container, path, strip_final_slash: true)
          FileUtils.mkdir_p mkpath
        end


        # Use the system mv command rather than FileUtils.
        # The latter appears to break on a file permissions error changing metadata
        # FileUtils.mv from_path, fs_path
        # returns: #<Errno::EPERM: Operation not permitted @ utime_internal ...>
        # fileutils.rb:1299:in `utime'
        # fileutils.rb:1299:in `copy_metadata'

        Kernel.system "mv", from_path, fs_path


        FileUtils.chmod FinalFilePerms, fs_path if FinalFilePerms
        return true
      end

      # Create a directory for a container container using the specified role name
      # Validates that the directory does not already exist (raises an exception if it does)
      # @param container [NfsStore::Manage::Container] container needing a directory
      # @param role_name [String] role name to use to select a mount point
      # @return [Boolean] on testing the existence of the directory after creation
      def self.create_container container, role_name

        fs_dir = nfs_store_path(role_name, container)
        unless File.exist? fs_dir
          FileUtils.mkdir_p fs_dir
          Rails.logger.info "Created container: #{fs_dir}"
        else
          FsException::Filesystem.new "Directory already existed when trying to create a new container: #{fs_dir}"
        end

        !!File.exist?(fs_dir)
      end

      # Ensure that the configurations are loaded from initializers
      ActiveSupport.run_load_hooks(:nfs_store_config, self)

    end
  end
end
