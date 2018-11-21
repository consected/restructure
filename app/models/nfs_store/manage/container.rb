module NfsStore
  module Manage
    class Container < UserBase

      self.table_name = 'nfs_store_containers'

      # include HandlesUserBase
      include UserHandler

      belongs_to :app_type
      has_many :stored_files, foreign_key: 'nfs_store_container_id', inverse_of: :container
      has_many :archived_files, foreign_key: 'nfs_store_container_id', inverse_of: :container

      validates :user, presence: true

      after_create :create_in_nfs_store

      attr_accessor :current_user, :create_with_role
      alias_attribute :container_id, :nfs_store_container_id


      def self.resource_name
        'nfs_store__manage__containers'
      end

      def self.human_name
        'File Container'
      end

      def data
        name
      end

      def human_name
        name
      end

      def resource_name
        self.class.resource_name
      end


      # Container-specific sub directory to place container directory into
      # @return [nil | String] set to a sub path string such as 'holder123' or 'parentdir/holder123'
      def parent_sub_dir
        upsd = Filesystem.use_parent_sub_dir
        if upsd
          setting = Admin::AppConfiguration.find_default_app_config(self.app_type_id, 'filestore directory id')
          if setting
            return "#{setting.value.hyphenate}-#{self.master.send(setting.value)}"
          else
            return "master-#{self.master_id}"
          end
        end
      end

      # # Container-specific sub directory to place container directory into
      # # Override method in app implementations if required
      # # @return [nil | String] set to a sub path string such as 'holder123' or 'parentdir/holder123'
      # def parent_sub_dir
      # end

      # All containers for the user's current app type. Returns an ActiveRecord::Relation that can be refined
      # @param user [User] the current user
      # @return [ActiveRecord::Relation] result set of all matching containers in this app type
      def self.for_current_app_type user
        app_type = user.app_type
        raise FsException::NoAccess.new "User has no access to this container's app-type" unless user.app_type_valid?

        self.where app_type: app_type
      end

      # Create a container record in the current app. After creation, #create_in_nfs_store is called by a callback
      # Raises an exception if validations fail during creation
      # @param user [User] the current user
      # @param name [String] the human readable name for the container
      # @param extra_params [Hash] additional parameters used to create the record
      # @return [NfsStore::Manage::Container] the instantiated container
      def self.create_in_current_app user: nil, name: nil, extra_params: {}
        app_type_id = user&.app_type_id
        FsException::Action.new "Cannot create a container with app_type: #{app_type_id}, user: #{user&.id}, name: #{name}" unless app_type_id && user && name.present?

        self.create! extra_params.merge(app_type_id: app_type_id, name: name, current_user: user)
      end

      # Set current user used when creating new containers
      # @param user [User] current user
      def current_user=user
        master.current_user = user
      end

      # Get the current user
      # @return [User]
      def current_user
        master.current_user
      end

      # Name of directory for container. This must be a single name and not contain backslashes
      # Can be overridden in app implementation, but beware not to change
      # after containers are created, since they will not be found
      # @return [String]
      def directory_name
        "#{self.id} -- #{self.name}"
      end

      # Get the first filsystem group gid that allows reading of the container directory,
      # based on the user the item was created with, not necessarily the current logged in user
      # @return [Integer] group gid
      def directory_group
        res = nil
        Group.role_names_for(user).each do |role_name|
          if Filesystem.test_dir role_name, self, :read
            res = File.stat(path_for role_name: role_name).gid
            break if res
          end
        end
        res
      end

      # Full filesystem path to the container directory for the current role
      # @param role_name [String] role name for the path
      # @return [String] full path to the container directory
      def path_for role_name: nil
        raise FsException::Action.new 'role_name must be specified' unless role_name
        Filesystem.nfs_store_path(role_name, self)
      end

      # Get the path to the parent directory of the container,
      # which may match the standard 'containers' directory if
      # parent_sub_dir has not been overridden
      # @return [String]
      def path_to_parent_dir_for role_name: nil
        parts = path_for(role_name: role_name).split('/')
        if parent_sub_dir.present?
          parts.pop
        end
        File.join parts
      end

      # All role names that the current user has assigned
      # @return [Array(String)] list of role names
      def current_user_role_names
        @current_user_role_names ||= Manage::Group.role_names_for self.current_user
      end

      # All group ID gids that the current user has assigned
      # @return [Array(Integer)] list of gids
      def current_user_group_ids
        @current_user_group_ids ||= Manage::Group.group_ids_for self.current_user
      end


      # Can files be read from the container directory?
      # @return [Boolean] true if readable, false if not
      def readable?
        current_user_role_names.each do |role_name|
          return true if Filesystem.test_dir role_name, self, :read
        end
        false
      end

      # Can files be written to the container directory?
      # @return [Boolean] true if writable, false if not
      def writable?
        current_user_role_names.each do |role_name|
          return true if Filesystem.test_dir role_name, self, :write
        end
        false
      end

      # Does the container directory exist?
      # @return [Boolean] true if it exists, false if not
      def exists?
        current_user_role_names.each do |role_name|
          return true if Filesystem.test_dir role_name, self, :exists
        end
        false
      end


      # Method to provide checking of access controls. Can the user access the container
      # in a specific way. Easily overridden in applications to provide app specific functionality
      # @param perform [Symbol(:list_files, :create_files)]
      def allows_current_user_access_to? perform, with_options=nil
        super
      end

      # List all the filesystem files in the container directory and sub-directories including files in the mounted archives too.
      # Iterates through all the roles that the current user has, building a complete, unique set of files based on the
      # appropriate group file permissions for each role.
      # @return [Array(String)] a list of file paths relative to the container directory
      def list_fs_files
        all_files = []
        current_user_role_names.each do |role_name|
          if Filesystem.test_dir role_name, self, :read
            p = path_for role_name: role_name
            # Don't use Regex - it breaks if there are special characters
            all_files += Dir.glob("#{p}/**/*").reject {|f| Pathname.new(f).directory?}.map {|f| f.sub("#{p}/", '').sub(p, '')}
          end
        end

        all_files.uniq
      end

      private

        # Create the container directory on the filesystem, using the first available role that provides this access if
        # a specific role is not specified
        # @param using_role [String] optional role to use for creation, otherwise use the first available role that works
        # @return [Boolean] success
        def create_in_nfs_store using_role: nil
          res = nil
          using_role ||= self.create_with_role

          if using_role
            roles = [using_role]
          else
            roles = current_user_role_names
          end
          roles.each do |role_name|
            if Filesystem.test_dir role_name, self, :mkdir
              res = Filesystem.create_container self, role_name
              break if res
            end
          end
          raise FsException::Action.new "Could not create a container. Maybe you don't have permission to store here. App type: #{user.app_type.name}. Name: #{self.name}. Roles: #{roles.join(", ")} " unless res
          true
        end


        # Hook allowing the class to be reopened safely in the initializers
        ActiveSupport.run_load_hooks(:nfs_store_container, self)
    end

  end
end
