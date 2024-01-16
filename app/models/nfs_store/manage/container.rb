# frozen_string_literal: true

module NfsStore
  module Manage
    class Container < UserBase
      self.table_name = 'nfs_store_containers'

      # include HandlesUserBase
      include UserHandler

      belongs_to :app_type, class_name: 'Admin::AppType'
      has_many :stored_files, foreign_key: 'nfs_store_container_id', inverse_of: :container
      has_many :archived_files, foreign_key: 'nfs_store_container_id', inverse_of: :container

      validates :user, presence: true

      after_create :create_in_nfs_store

      attr_accessor :create_with_role, :parent_item, :previous_uploads, :previous_upload_stored_file_ids

      alias_attribute :container_id, :nfs_store_container_id

      def self.resource_name
        'nfs_store__manage__containers'
      end

      def self.category
        :nfs_store
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
        return unless Filesystem.use_parent_sub_dir

        setting = Admin::AppConfiguration.find_default_app_config(app_type_id, 'filestore directory id')
        if setting
          unless setting.value.in?(Master.alternative_id_fields.map(&:to_s))
            raise FsException, 'An id name ending with "_id" is expected for "filestore directory id"'
          end

          "#{setting.value.hyphenate}-#{master.send(setting.value)}"
        else
          "master-#{master_id}"
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
      def self.for_current_app_type(user)
        app_type = user.app_type
        raise FsException::NoAccess, "User has no access to this container's app-type" unless user.app_type_valid?

        where app_type: app_type
      end

      # Create a container record in the current app. After creation, #create_in_nfs_store is called by a callback
      # Raises an exception if validations fail during creation
      # @param user [User] the current user
      # @param name [String] the human readable name for the container
      # @param extra_params [Hash] additional parameters used to create the record
      # @return [NfsStore::Manage::Container] the instantiated container
      def self.create_in_current_app(user: nil, name: nil, extra_params: {})
        app_type_id = user&.app_type_id
        unless app_type_id && user && name.present?
          FsException::Action.new "Cannot create a container with app_type: #{app_type_id}, user: #{user&.id}, name: #{name}"
        end

        create! extra_params.merge(app_type_id: app_type_id, name: name, current_user: user)
      end

      #
      # Get the container referenced by the specified item, or nil if there isn't one
      # @param [ActiveRecord::Model] for_item
      # @return [NfsStore::Manage::Container | nil]
      def self.referenced_container(for_item)
        ModelReference.find_referenced_items(for_item, record_type: 'NfsStore::Manage::Container').first
      end

      # Set current user used when creating new containers
      # @param user [User] current user
      def current_user=(user)
        master.current_user = user
      end

      # Get the current user
      # @return [User]
      def current_user
        master.current_user
      end

      def extra_options_config
        parent_item&.extra_log_type_config
      end

      # Find the parent item (activity log) that created the container
      # by looking for the first model reference
      # @return [ActivityLog]
      #
      def find_creator_parent_item
        ModelReference.find_where_referenced_from(self).first&.from_record
      end

      # Inform the container that a set of uploads have completed
      # This may cause notifications or other events to fire
      # @param ids [Array] integer IDs for the Upload records
      def upload_done(ids)
        # Forces a check that the supplied info is correct
        self.previous_uploads = ids.map { |id| NfsStore::Upload.find(id) }
        self.previous_upload_stored_file_ids = previous_uploads.map(&:nfs_store_stored_file_id)

        # Get any uploads that already have an upload_set, since it is invalid to reset it
        raise FsException::Action, "Upload set files don't match" if previous_uploads.map(&:upload_set).uniq.length != 1

        return unless parent_item&.can_edit?

        extra_options_config.calc_save_trigger_if self, alt_on: :upload
      end

      # # Filter upload notification users based on file filters
      # def filter_notifications users
      #
      #   pi = self.parent_item
      #   return unless pi
      #
      #   users.select do |user|
      #     user = User.find(user) if user.is_a? Integer
      #
      #     user_files = NfsStore::Filter::Filter.evaluate_container_files pi, user: user
      #     # Get all the stored file IDs
      #     tot_files = user_files.map {|f| f.is_a?(StoredFile) ? f.id : f.stored_file }.uniq
      #
      #     # The intersection of uploaded files with the available filtered files shows which of the uploaded files are visible to the user
      #     up_files = self.previous_upload_stored_file_ids & tot_files
      #     up_files.length > 0
      #   end
      #
      # end

      # Name of directory for container. This must be a single name and not contain backslashes
      # Can be overridden in app implementation, but beware not to change
      # after containers are created, since they will not be found
      # @return [String]
      def directory_name
        "#{id} -- #{name}"
      end

      # Get the first filsystem group gid that allows reading of the container directory,
      # based on the user the item was created with, not necessarily the current logged in user
      # @return [Integer] group gid
      def directory_group
        res = nil
        Group.role_names_for(user).each do |role_name|
          if Filesystem.test_dir role_name, self, :read
            res = File.stat(path_for(role_name: role_name)).gid
            break if res
          end
        end
        res
      end

      # Full filesystem path to the container directory for the current role
      # @param role_name [String] role name for the path
      # @return [String] full path to the container directory
      def path_for(role_name: nil)
        raise FsException::Action, 'role_name must be specified' unless role_name

        Filesystem.nfs_store_path(role_name, self)
      end

      # Get the path to the parent directory of the container,
      # which may match the standard 'containers' directory if
      # parent_sub_dir has not been overridden
      # @return [String]
      def path_to_parent_dir_for(role_name: nil)
        parts = path_for(role_name: role_name).split('/')
        parts.pop if parent_sub_dir.present?
        File.join parts
      end

      # All role names that the current user has assigned
      # @return [Array(String)] list of role names
      def current_user_role_names
        @current_user_role_names ||= Manage::Group.role_names_for current_user
      end

      # All group ID gids that the current user has assigned
      # @return [Array(Integer)] list of gids
      def current_user_group_ids
        @current_user_group_ids ||= Manage::Group.group_ids_for current_user
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

      def can_edit?
        res = allows_current_user_access_to? :edit
        return unless res

        res = parent_item.can_edit? if parent_item
        !!res
      end

      def can_download_or_view?
        return @can_download_or_view unless @can_download_or_view.nil?

        cu = current_user
        @can_download_or_view = can_download? || can_view?
      end

      def can_download?
        return @can_download unless @can_download.nil?

        @can_download = eval_uac_and_perform_if?(:download_files)
      end

      def can_view?
        return @can_view unless @can_view.nil?

        @can_view = can_view_files_as_html? || can_view_files_as_image?
      end

      def can_view_files_as_html?
        return @can_view_files_as_html unless @can_view_files_as_html.nil?

        @can_view_files_as_html = eval_uac_and_perform_if?(:view_files_as_html)
      end

      def can_view_files_as_image?
        return @can_view_files_as_image unless @can_view_files_as_image.nil?

        @can_view_files_as_image = eval_uac_and_perform_if?(:view_files_as_image)
      end

      def can_send_to_trash?
        return @can_send_to_trash unless @can_send_to_trash.nil?

        @can_send_to_trash = eval_uac_edit_or_perform_if?(:send_files_to_trash)
      end

      def can_move_files?
        return @can_move_files unless @can_move_files.nil?

        @can_move_files = eval_uac_edit_or_perform_if?(:move_files)
      end

      #
      # Can perform user_file_actions if:
      # current user has user access control for user_file_actions
      # and
      #   nfs_store: can: user_file_actions_if: is not defined AND user can edit this container
      #   OR nfs_store: can: user_file_actions_if: evaluates to true
      # @return [true|false]
      def can_user_file_actions?
        return @can_user_file_actions unless @can_user_file_actions.nil?

        @can_user_file_actions = eval_uac_edit_or_perform_if?(:user_file_actions)
      end

      # Method to provide checking of access controls. Can the user access the container
      # in a specific way. Easily overridden in applications to provide app specific functionality
      # @param perform [Symbol(:list_files, :create_files)]
      def allows_current_user_access_to?(perform, with_options = nil)
        super
      end

      # List all the filesystem files in the container directory and sub-directories
      # including files in the mounted archives too.
      # It excludes .trash paths and hidden (dot) paths and files
      # Iterates through all the roles that the current user has, building a complete, unique set of files based on the
      # appropriate group file permissions for each role.
      # @return [Array(String)] a list of file paths relative to the container directory
      def list_fs_files
        all_files = []
        current_user_role_names.each do |role_name|
          next unless Filesystem.test_dir role_name, self, :read

          p = path_for role_name: role_name
          # Don't use Regex - it breaks if there are special characters
          paths = Dir.glob("#{p}/**/*").reject do |f|
            Pathname.new(f).directory?
          end

          all_files += paths.map { |f| f.sub("#{p}/", '').sub(p, '') }
        end

        all_files.uniq
      end

      def user_file_actions_config
        nfs_store_config_for(:user_file_actions)
      end

      def view_options
        nfs_store_config_for(:view_options)
      end

      def show_file_links_as_path
        view_options&.dig(:show_file_links_as) == 'path'
      end

      #
      # Evaluate if a user can perform an action against the current container,
      # based on the nfs_store: can: <perform>_if: configuration
      # If there is no configuration, then return :no_config, since a lack of configuration
      # indicates that the default should be used for the action
      # @param [String|Symbol] perform - the action to test
      # @return [Object]
      def can_perform_if?(perform)
        return unless parent_item

        perform = perform.to_sym
        @can_perform_if ||= {}
        return @can_perform_if[perform] if @can_perform_if.key?(perform)

        config = can_perform_if_config(perform)
        return @can_perform_if[perform] = :no_config unless config

        Rails.logger.debug "Checking nfs_store can_perform_if? with #{perform} on #{parent_item} with #{config}"
        ca = ConditionalActions.new config, parent_item
        @can_perform_if[perform] = ca.calc_action_if
      end

      def raise_if_no_access!
        return if allows_current_user_access_to? :access

        cp = parent_item
        cpm = cp&.master&.id if cp.respond_to?(:master)

        raise FsException::NoAccess,
              'User does not have access to this container ' \
              "(master #{master&.id} - parent #{cp.class} id: #{cp&.id} master: #{cpm})"
      end

      def raise_if_action_not_authorized!(for_action)
        return if send("can_#{for_action}?")

        raise FsException::NoAccess, "user is not authorized to #{for_action.to_s.humanize}"
      end

      def raise_if_no_activity_log_specified!(activity_log)
        return if activity_log

        res = ModelReference.find_where_referenced_from(self).first
        return unless res

        raise FsException::NoAccess,
              'Attempting to browse a container that is referenced by activity logs, without specifying which one'
      end

      private

      def eval_uac_and_perform_if?(perform)
        perform = perform.to_sym
        cu = current_user
        !!(cu.can?(perform) && can_perform_if?(perform))
      end

      def eval_uac_edit_or_perform_if?(perform)
        perform = perform.to_sym
        cu = current_user
        !!(cu.can?(perform) && (
            can_perform_if?(perform) == :no_config && can_edit? ||
            can_perform_if?(perform)
          ))
      end

      #
      # Get a nfs_store: can: <perform>_if: configuration.
      # Returns nil if not defined.
      # @param [String|Symbol] perform - the action to test
      # @return [Object]
      def can_perform_if_config(perform)
        perform = "#{perform}_if".to_sym
        nfs_store_config_for(:can)&.dig(perform)
      end

      #
      # Get the nfs_store configuration for a specific setting,
      # from activity log extra options if the nfs_store section is set.
      # Returns nil if there is no nfs_store section, or the setting is not present
      # @param [Symbol] setting
      # @return [Object]
      def nfs_store_config_for(setting)
        extra_options_config.nfs_store[setting] if extra_options_config&.nfs_store
      end

      # Create the container directory on the filesystem, using the first available role that provides this access if
      # a specific role is not specified
      # @param using_role [String] optional role to use for creation, otherwise use the first available role that works
      # @return [Boolean] success
      def create_in_nfs_store(using_role: nil)
        res = nil
        using_role ||= create_with_role

        roles = if using_role
                  [using_role]
                else
                  current_user_role_names
                end
        roles.each do |role_name|
          next unless Filesystem.test_dir role_name, self, :mkdir

          res = Filesystem.create_container self, role_name
          break if res
        end

        unless res
          raise FsException::Action, "Could not create a container. Maybe you don't have permission to store here. "\
                                          "App type: #{user.app_type.name} (#{user.app_type.id}). "\
                                          "Name: #{name}. "\
                                          "Roles: #{roles.join(', ')}"
        end

        true
      end

      # Hook allowing the class to be reopened safely in the initializers
      ActiveSupport.run_load_hooks(:nfs_store_container, self)
    end
  end
end
