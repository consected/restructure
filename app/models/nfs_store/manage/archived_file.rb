module NfsStore
  module Manage
    class ArchivedFile < ContainerFile

      self.table_name = 'nfs_store_archived_files'

      include HandlesContainerFile

      # Analyze the file to complete its ArchivedFile attributes
      def analyze_file!
        rp = archive_retrieval_path
        raise FsException::Action.new "Retrieval path is not set when analyzing file '#{path}' '#{file_name}'. Does gid #{self.current_gid} have permissions for this app / container?" unless rp
        self.skip_file_uniqueness = true # Just rely on the database, to avoid slow queries by Rails
        super(rp)
      end

      # Has the archive been extracted and stored to the DB?
      # @param container [NfsStore::Manage::Container] the container holding the archive
      # @param archive_path [String] the relative path (from the container) to the archive if it is not in the root
      # @param archive_file_name [String] the file name of the archive file
      # @return [Boolean] true if the archive has been extracted leading to at least one entry in the database
      def self.extracted? container, archive_path, archive_file_name
        archive_file_parts = []
        archive_file_parts << archive_path if archive_path
        archive_file_parts << archive_file_name
        archive_file = File.join(archive_file_parts)
        !!where(container: container, archive_file: archive_file).first
      end

      # Name of the mounted archive, which is the directory name of the mount point
      # @return [String] the mount point name
      def archive_mount_name
        NfsStore::Archive::Mounter.archive_mount_name self.archive_file
      end

      # Full retrieval path for the specific archive file within the mounted archive
      # @return [String] full path
      def archive_retrieval_path
        raise FsException::Container.new 'No current role name set' unless self.current_role_name
        path_for role_name: self.current_role_name
      end

      # File path relative to the container, returning results based on multiple options
      # @param no_filename [Boolean] default (falsey) the filename is returned, otherwise (true) it is not
      # @param final_slash [Boolean] default (falsey) the final slash is not included on a directory path, otherwise (true) the final slash is included
      # @param use_archive_file_name [Boolean] default (falsey) the archive mount name is used, otherwise (true) the original archive file name is used instead
      # @param leading_dot [Boolean] default (falsey) do not include a leading dot, otherwise (true) the leading dot is included in the path
      def container_path no_filename: nil, final_slash: nil, use_archive_file_name: nil, leading_dot: nil
        parts = []
        parts << '.' if leading_dot
        if use_archive_file_name
          parts << archive_file
        else
          parts << archive_mount_name
        end
        parts << path unless path.blank?
        parts << file_name unless no_filename
        res = File.join parts
        res = res + '/' if final_slash && res.length > 0
        res
      end

    end
  end
end
