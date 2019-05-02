module NfsStore
  module Manage
    class StoredFile < ContainerFile

      self.table_name = 'nfs_store_stored_files'

      include HandlesContainerFile

      has_many :archived_files, foreign_key: 'nfs_store_stored_file_id', inverse_of: :stored_file
      validate :not_named_like_archive

      # Finalize an upload, moving a file from its temporary upload location to the file location and mounting the archive if necessary
      # @param orig_file_obj [NfsStore::Upload] the original upload instance with file information
      # @param [String] the temporary file path to be moved from
      # @return [NfsStore::Manage::StoredFile] the generated stored file object
      def self.finalize_upload orig_file_obj, from_path
        attrs = orig_file_obj.attributes.slice(*(self.attribute_names - ['nfs_store_container_id', 'id', 'user_id']))
        stored_file = orig_file_obj.container.stored_files.build attrs
        stored_file.container.current_user = orig_file_obj.container.current_user

        stored_file.move_from from_path
        # Do not mount archive here - it will be done on retrieval and will avoid any unforseen issues after a lengthy upload
        # stored_file.mount_archive
        stored_file.analyze_file!
        stored_file.save!
        stored_file
      end

      # Analyze the file to complete its StoredFile attributes
      def analyze_file!
        rp = retrieval_path
        raise FsException::Action.new "Retrieval path is not set when analyzing file '#{path}' '#{file_name}'. Does gid #{self.current_gid} have permissions for this app / container?" unless rp
        super(rp)
      end


      # Mount an archive file, if necessary (idempotent)
      def mount_archive
        Archive::Mounter.mount self
      end

      # File path relative to the container, returning results based on multiple options
      # @param no_filename [Boolean] default (falsey) the filename is returned, otherwise (true) it is not
      # @param final_slash [Boolean] default (falsey) the final slash is not included on a directory path, otherwise (true) the final slash is included
      # @param use_archive_file_name [Boolean] unused in this implementation
      # @param leading_dot [Boolean] default (falsey) do not include a leading dot, otherwise (true) the leading dot is included in the path
      def container_path no_filename: nil, final_slash: nil, use_archive_file_name: nil, leading_dot: nil
        parts = []
        parts << '.' if leading_dot
        parts << path unless path.blank?
        parts << file_name unless no_filename
        res = File.join parts
        res = res + '/' if final_slash && res.length > 0
        res
      end

      # Shortcut way to check if a stored file is a compressed archive
      # @return [Boolean] true if the file is an archive
      def is_archive?
        NfsStore::Archive::Mounter.has_archive_extension? self
      end

      def not_named_like_archive
        if NfsStore::Archive::Mounter.path_is_archive?(self.file_name) || NfsStore::Archive::Mounter.path_is_archive?(self.path)
          errors.add :file_name, 'has an invalid name. Rename before attempting to upload.'
          return false
        end
        true
      end

    end
  end
end
