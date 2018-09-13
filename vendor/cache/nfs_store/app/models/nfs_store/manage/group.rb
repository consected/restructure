module NfsStore
  module Manage
    class Group
      RoleNamePrefix = 'nfs_store group '
      NfsMountNamePrefix = 'gid'

      # Configuration of valid filesystem group ID gids
      # @return [Range] like 600..610
      def self.group_id_range
        Filesystem.group_id_range
      end

      # Valid role names based on #group_id_range
      # @return [Array(String)] role names based on RoleNamePrefix
      def self.valid_role_names
        group_id_range.map {|id| role_name_from_id(id) }
      end

      # Lookup role names that a user has assigned roles for.
      # Ensures the roles are active and from the list of #valid_role_names
      # @return [Array(String)] role names
      def self.role_names_for user
        user.user_roles.active.where(role_name: valid_role_names).role_names
      end

      # List of group ID gids for the current user, based on current active roles
      # @return [Array(Integer)] gid list
      def self.group_ids_for user
        self.role_names_for(user).map {|name| group_id_from_role_name(name) }
      end

      # Generate role name from group ID gid. Does not check that the gid is in a valid range
      # @return [String] role name
      def self.role_name_from_id id
        "#{RoleNamePrefix}#{id}"
      end

      # Get the group ID gid from the role name. The role name is validated initially.
      # @param role_name [String] role name
      # @return [Integer] gid
      def self.group_id_from_role_name role_name
        raise FsException::Action.new "Invalid role name: #{role_name}" unless valid_role_names.include? role_name

        id = role_name.sub(RoleNamePrefix, '').to_i
        id
      end

      # NFS mount point name based on the role name
      # @param role_name [String] role name for mount
      # @return [String] mount point name
      def self.nfs_mount_from_role_name role_name
        if role_name.start_with?(RoleNamePrefix)
          group_id = group_id_from_role_name(role_name) if role_name && !group_id
          raise FsException.new "role name group ID is incorrect" unless group_id.in? self.group_id_range

          "#{NfsMountNamePrefix}#{group_id}"
        else
          raise FsException.new "role name is incorrect"
        end
      end
    end
  end
end
