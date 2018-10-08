module NfsStore
  class Browse

    include HasCurrentUser


    # List all the files in the specified container. This includes all
    # stored files, extracted archive files and those that are on the file system but do not have a
    # record entered in the database.
    # @param container [NfsStore::Manage::Container] the container to list
    # @return [Array(ContainerFile)] list of ContainerFile subclass instances sorted by path
    def self.list_files_from container, activity_log: nil

      raise FsException::NotFound.new "Container nfs_store storage is not found: #{container.name}" unless container.exists?
      raise FsException::NoAccess.new "User does not have access to this container" unless container.allows_current_user_access_to? :access

      # Make sure the archive files are mounted (this is idempotent), but not immediate
      Archive::Mounter.mount_all container.stored_files

      unless activity_log
        res = ModelReference.find_where_referenced_from(container).first
        raise FsException::NoAccess.new "Attempting to browse a container that is referenced by activity logs, without specifying which one" if res
      end

      item_for_filter = activity_log || container

      all_db_files = NfsStore::Filter::Filter.evaluate_container_files item_for_filter


      # Get the filesystem files, so we can find out if any don't have DB records
      fs_files = container.list_fs_files

      selected_db_files = all_db_files.select {|f| f.container_path.in? fs_files}
      missing_db_files = fs_files - selected_db_files.map(&:container_path)

      # Instantiate a stored file for each of the missing files
      # These are not persisted, therefore can be identified. We may also choose to
      # easily instantiate them in the future if we need to (though we'll want to analyze_file! to complete it)
      missing_db = []
      missing_db_files.each do |f|
        pn = Pathname.new f

        can_show = NfsStore::Filter::Filter.evaluate f, item_for_filter

        missing_db << Manage::StoredFile.new(path: pn.dirname, file_name: pn.basename) if can_show
        # missing_db.analyze_file!
      end

      # The result is a sorted list of all the DB files and files missing DB entries, sorted by the container path
      (selected_db_files + missing_db).sort{|a, b| a.container_path(leading_dot: true).downcase <=> b.container_path(leading_dot: true).downcase}

    end

  end
end
