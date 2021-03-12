# frozen_string_literal: true

module NfsStore
  #
  # Wrapper to simplify the import of files into containers, without having to
  # deal with the complexity of uploads.
  class Import < NfsStoreUserBase
    self.table_name = 'nfs_store_imports'

    include HandlesContainerFile
    include HasCurrentUser

    attr_accessor :file_size, :content_type, :file_updated_at

    #
    # Import a single file from a file path into a container.
    # An Import object is instantiated to represent the
    # all the information expected to finalize and upload, so it is effectively
    # pretending to be the result of a completed upload.
    # @param [Integer] container_id
    # @param [String] file_name
    # @param [String] file_path - absolute path to the file to import
    # @param [User] current_user
    # @param [String] path - container path to stored file
    # @param [Boolean] skip_existing - return if a file with the same name and path exists in this container
    # @param [Boolean] replace - if a file with the same name and path exists, but has changed based on the file hash
    # @return [NfsStore::Manage::StoredFile]
    def self.import_file(container_id, file_name, file_path, current_user,
                         path: nil, skip_existing: nil, replace: nil)
      file_path = NfsStore::Manage::Filesystem.clean_path file_path

      transaction do
        # Set up an import object based on the file to import
        import = new
        import.container = Browse.open_container(id: container_id, user: current_user)
        import.file_name = file_name
        import.user = current_user
        import.current_user = current_user
        import.path = path
        import.file_hash = hash_for_file(file_path)

        # Check if the file exists in the container, based on path and file name
        already_in = import.already_in_container
        return if skip_existing && already_in

        # Check if an identical file is in the container, based on path, file name and content
        identical_in = import.identical_in_container
        return if identical_in

        if already_in # exists (based on path / file name) but is not identical (based on the hash)
          return unless replace

          # We have been told to replace existing files that are not identical
          already_in.replace_file!(file_path)
          already_in
        else # does not exist
          import.analyze_file! file_path
          import.save!
          Manage::StoredFile.finalize_upload import, file_path
        end
      end
    end

    #
    # Check if a file exists in a container,
    # checking on the existence based on file name and path
    # @return [NfsStore::Manage::StoredFile]
    def already_in_container
      container.stored_files.where(file_name: file_name,
                                   path: path).first
    end

    #
    # Check if an identical file is already in a container,
    # based on its file name, path and hash digest matching.
    # @return [NfsStore::Manage::StoredFile]
    def identical_in_container
      container.stored_files.where(file_name: file_name,
                                   path: path,
                                   file_hash: file_hash).first
    end
  end
end
