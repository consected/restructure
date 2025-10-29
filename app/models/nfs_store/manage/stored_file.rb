# frozen_string_literal: true

module NfsStore
  module Manage
    class StoredFile < ContainerFile
      self.table_name = 'nfs_store_stored_files'

      include HandlesContainerFile

      has_many :archived_files, foreign_key: 'nfs_store_stored_file_id', inverse_of: :stored_file
      has_one :upload, foreign_key: 'nfs_store_stored_file_id', inverse_of: :stored_file

      validate :not_named_like_archive

      # Finalize an upload, moving a file from its temporary upload location to the file location and mounting the
      # archive if necessary
      # @param orig_file_obj [NfsStore::Upload] the original upload instance with file information
      # @param [String] the temporary file path to be moved from
      # @return [NfsStore::Manage::StoredFile] the generated stored file object
      def self.finalize_upload(orig_file_obj, from_path)
        attrs = orig_file_obj.attributes.slice(*(attribute_names - ['nfs_store_container_id', 'id', 'user_id']))
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
        unless rp
          raise FsException::Action,
                "Retrieval path is not set when analyzing file '#{path}' '#{file_name}'. Does gid #{current_gid} have permissions for this app / container?"
        end

        super(rp)
      end

      # Mount an archive file, if necessary (idempotent)
      def mount_archive
        Archive::Mounter.mount self
      end

      #
      # Add stored file entry for a file without a current database entry
      # Persist to database if persist: true
      # <Description>
      # @param [String] path - The full retrieval path to the file
      # @param [String] file_name - Filename
      # @param [Boolean] persist - Whether to persist the entry to the database
      # @param [NfsStore::Container] container - The container the file belongs to
      # @param [User] current_user - Current user, which will be set if the container doesn't supply it
      # @return [NfsStore::Manage::StoredFile] The new or persisted stored file
      def self.index_missing_entry(path:, file_name:,
                                   persist: nil, container: nil, current_user: nil)
        msf = Manage::StoredFile.new(path:, file_name:, container: container)
        msf.current_user ||= current_user

        # If the file is actually in an extracted archive folder, just return it - don't attempt to persist
        return msf if msf.named_like_archive?

        mounter = NfsStore::Archive::Mounter.new(stored_file: msf)
        # If the file is a failed archive indicator, get its content which has the failure reason
        msf.title = mounter.extract_failure_reason if mounter.failed_indicator?

        # If requested not to persist just return the StoredFile
        return msf unless persist

        # If file is an indicator file always return
        if file_is_indicator?(file_name)
          # Also check if it has timed out. If it has, nothing should be returned as the file
          # has been cleaned up
          return if mounter.indicator_timed_out?(clear: true)

          # Otherwise return the StoredFile
          return msf
        end

        msf.analyze_file!
        msf.file_hash = msf.class.hash_for_file(msf.retrieval_path)
        begin
          msf.save!
        rescue FsException::Action, StandardError => e
          msf.title = "Failed to index file - #{e.message}"
          Rails.logger.warn "Failed to index missing entry #{path} / #{file_name} - container #{container.id}"
          Rails.logger.warn "#{e}\n#{e.short_string_backtrace}"
        end
        msf
      end

      # File path relative to the container, returning results based on multiple options
      # @param no_filename [Boolean] default (falsey) the filename is returned, otherwise (true) it is not
      # @param final_slash [Boolean] default (falsey) the final slash is not included on a directory path, otherwise (true) the final slash is included
      # @param use_archive_file_name [Boolean] unused in this implementation
      # @param leading_dot [Boolean] default (falsey) do not include a leading dot, otherwise (true) the leading dot is included in the path
      def container_path(no_filename: nil, final_slash: nil, use_archive_file_name: nil, leading_dot: nil)
        parts = []
        parts << '.' if leading_dot
        parts << path unless path.blank?
        parts << file_name unless no_filename
        res = File.join parts
        res += '/' if final_slash && !res.empty?
        res
      end

      def named_like_archive?
        NfsStore::Archive::Mounter.path_is_archive?(file_name) || NfsStore::Archive::Mounter.path_is_archive?(path)
      end

      def not_named_like_archive
        if named_like_archive?
          errors.add :file_name, 'has an invalid name. Rename before attempting to upload.'
          return false
        end
        true
      end

      Resources::Models.add self, resource_name: :nfs_store__manage__stored_files
    end
  end
end
