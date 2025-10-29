module NfsStore
  class Browse
    include HasCurrentUser

    # List all the files in the specified container. This includes all
    # stored files, extracted archive files and those that are on the file system but do not have a
    # record entered in the database.
    # @param [NfsStore::Manage::Container] container the container to list
    # @param [ActivityLog | nil] activity_log - optional activity log owner of the container
    # @param [Array] | nil] include_flags - optional list of container file types to include item_flags for
    # @param [Boolean] index_missing_entries - (default true) will index filesystem files with missing DB entries
    # @return [Array(ContainerFile)] list of ContainerFile subclass instances sorted by path
    def self.list_files_from(container,
                             activity_log: nil,
                             include_flags: nil,
                             index_missing_entries: true)
      unless container.exists?
        raise FsException::NotFound, "Container nfs_store storage is not found: #{container.name}"
      end

      container.parent_item ||= activity_log || container.find_creator_parent_item

      container.raise_if_no_access!

      orig_user = container.current_user
      # Make sure the archive files are mounted (this is idempotent), but not immediate
      Archive::Mounter.mount_all container.stored_files
      container.current_user = orig_user

      container.raise_if_no_activity_log_specified!(activity_log)

      item_for_filter = activity_log || container

      all_db_files = NfsStore::Filter::Filter.evaluate_container_files item_for_filter, include_flags: include_flags

      # Get the filesystem files, so we can find out if any don't have DB records
      fs_files = container.list_fs_files

      # Select the DB files that are in the filesystem list
      # Files that have been moved or deleted will therefore be excluded
      selected_db_files = all_db_files.select { |f| f.container_path.in? fs_files }
      # Find the filesystem files that do not have a DB record
      missing_db_files = fs_files - selected_db_files.map(&:container_path)

      # Instantiate a stored file for each of the missing files.
      # If any of the files are indicator files, they will be skipped,
      # and will be returned as a StoredFile but not persisted to the database.
      # ArchivedFile entries related to any StoredFile records added here
      # will be added automatically.
      # Existing archived files appear in the missing_db_files list in directories
      # identified as mounted archives. These must be skipped to avoid storing
      # extracted ArchiveFile filesystem files as StoredFile records.
      missing_db = []
      missing_db_files.each do |f|
        pn = Pathname.new f
        can_show = NfsStore::Filter::Filter.evaluate f, item_for_filter
        next unless can_show

        msf = NfsStore::Manage::StoredFile.index_missing_entry path: pn.dirname,
                                                               file_name: pn.basename,
                                                               persist: index_missing_entries,
                                                               container:,
                                                               current_user: orig_user
        # It's possible that the result was `nil`, typically indicating that an indicator file
        # had been cleaned up after a timeout period had elapsed. Just skip this if the
        # result is not a StoredFile
        next unless msf.is_a? NfsStore::Manage::StoredFile

        missing_db << msf
      end

      # The result is a sorted list of all the DB files and files missing DB entries, sorted by the container path
      (selected_db_files + missing_db).sort do |a, b|
        a.container_path(leading_dot: true).downcase <=> b.container_path(leading_dot: true).downcase
      end
    end
  end
end
