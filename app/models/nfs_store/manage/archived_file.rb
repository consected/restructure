# frozen_string_literal: true

module NfsStore
  module Manage
    class ArchivedFile < ContainerFile
      self.table_name = 'nfs_store_archived_files'

      include HandlesContainerFile

      belongs_to :stored_file, class_name: 'NfsStore::Manage::StoredFile',
                               foreign_key: 'nfs_store_stored_file_id',
                               optional: true

      # Analyze the file to complete its ArchivedFile attributes
      def analyze_file!
        rp = archive_retrieval_path
        unless rp
          raise FsException::Action, "Retrieval path is not set when analyzing file '#{path}' '#{file_name}'." \
                                     "Does gid #{current_gid} have permissions for this app / container?"
        end

        self.skip_file_uniqueness = true # Just rely on the database, to avoid slow queries by Rails
        super(rp)
      end

      # Has the archive been extracted and stored to the DB (but not subsequently been trashed)?
      # @param container [NfsStore::Manage::Container] the container holding the archive
      # @param archive_path [String] the relative path (from the container) to the archive if it is not in the root
      # @param archive_file_name [String] the file name of the archive file
      # @return [Boolean] true if the archive has been extracted leading to at least one entry in the database
      def self.extracted?(container = nil, archive_path = nil, archive_file_name = nil, stored_file: nil)
        if stored_file
          af = stored_file.archived_files.last
          return unless af

          !ContainerFile.trash_path?(af.path)
        elsif !(container || archive_path || archive_file_name)
          raise FsException::Archive, "Can't check if a file is extracted with no parameters"
        else
          archive_file_parts = []
          archive_file_parts << archive_path.to_s if archive_path
          archive_file_parts << archive_file_name.to_s
          archive_file = File.join(archive_file_parts)
          !!where(container: container, archive_file: archive_file).first
        end
      end

      # Name of the mounted archive, which is the directory name of the mount point
      # @return [String] the mount point name
      def archive_mount_name
        NfsStore::Archive::Mounter.archive_mount_name archive_file
      end

      # Full retrieval path for the specific archive file within the mounted archive
      # @return [String] full path
      def archive_retrieval_path
        raise FsException::Container, 'No current role name set' unless current_role_name

        path_for role_name: current_role_name
      end

      # File path relative to the container, returning results based on multiple options.
      # NOTE: we use a lot of #to_s calls in here to avoid holding unnecessary references to objects
      # especially in a large container lists. This appears to help memory cleanup significantly
      # @param no_filename [Boolean] default (falsey) the filename is returned, otherwise (true) it is not
      # @param final_slash [Boolean] default (falsey) the final slash is not included on a directory path,
      #     otherwise (true) the final slash is included
      # @param use_archive_file_name [Boolean] default (falsey) the archive mount name is used,
      #     otherwise (true) the original archive file name is used instead
      # @param leading_dot [Boolean] default (falsey) do not include a leading dot,
      #     otherwise (true) the leading dot is included in the path
      def container_path(no_filename: nil, final_slash: nil, use_archive_file_name: nil, leading_dot: nil)
        parts = []
        parts << '.' if leading_dot
        if use_archive_file_name && archive_file.present?
          parts << archive_file.to_s
        elsif archive_mount_name.present?
          parts << archive_mount_name.to_s
        end
        parts << path.to_s unless path.blank?
        parts << file_name.to_s unless no_filename
        res = File.join parts
        res += '/' if final_slash && res.present?
        res.to_s
      end

      # It is possible that repeated or overlapping background processes lead to double entries in the archive_files
      # table. Remove these by associating the earlier duplicates with a "duplicates-<timestamp>" archive file.
      # @param [String] archive_file - the name of the archive file within which to remove duplicate entries
      def self.remove_duplicates(archive_file)
        remove_dups = <<~END_SQL
          UPDATE nfs_store_archived_files
          SET file_name = $1
          WHERE
          archive_file = $2 AND
          id NOT IN (
            SELECT id FROM
            (
              SELECT MAX(t.id) id
                  , t.file_hash
                  , t.file_name
              FROM nfs_store_archived_files t
              WHERE archive_file = $3
              GROUP BY file_hash, file_name
            ) t
          );
        END_SQL

        bind_type = ActiveRecord::Type::String.new
        binds = [
          ActiveRecord::Relation::QueryAttribute.new('file_name', "duplicates-#{DateTime.now.to_f}", bind_type),
          ActiveRecord::Relation::QueryAttribute.new('archive_file', archive_file, bind_type),
          ActiveRecord::Relation::QueryAttribute.new('t.archive_file', archive_file, bind_type)
        ]

        connection.exec_query(remove_dups, 'SQL', binds)
      end

      #
      # Override the container to use the stored file container if the parent_item is not set in this one
      # @return [NfsStore::Manage::Container]
      def container
        return super if super.parent_item

        stored_file.container
      end

      Resources::Models.add self, resource_name: :nfs_store__manage__archived_files
    end
  end
end
