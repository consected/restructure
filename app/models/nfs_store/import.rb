module NfsStore
  class Import < NfsStoreUserBase
    self.table_name = 'nfs_store_imports'

    include HandlesContainerFile
    include HasCurrentUser

    attr_accessor :path, :file_size, :content_type, :file_updated_at

    def self.import_file container_id, file_name, file_path, current_user

      file_path = NfsStore::Manage::Filesystem.clean_path file_path

      transaction do
        import = self.new

        import.container = Browse.open_container(id: container_id, user: current_user)

        import.file_name = file_name
        import.user = current_user
        import.current_user = current_user
        import.path = nil
        import.file_hash = hash_for_file(file_path)
        import.analyze_file! file_path
        import.save!
        Manage::StoredFile.finalize_upload import, file_path
      end

    end

  end
end
