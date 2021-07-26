# frozen_string_literal: true

require 'mime/types'

module NfsStore
  module HandlesContainerFile
    extend ActiveSupport::Concern

    UnknownMimeTypeText = '(unknown)'

    # ChunkSize controls the size of upload chunks and the size of MD5 hash chunks
    ChunkSize = 10_000_000
    # Large archive files (files in mounted archives) are hard to deal with
    # We don't attempt to MD5 anything that is too big. This sets the limit
    MaxSizeForArchiveFileHash = ChunkSize * 5

    included do
      belongs_to :container, class_name: 'NfsStore::Manage::Container', foreign_key: 'nfs_store_container_id'

      belongs_to :user

      before_validation :clean_path

      validates :user_id, presence: true
      validates :file_hash, presence: { message: 'must be stored for file.' }

      validates :file_name, presence: true
      validates :file_size, presence: true
      validates :content_type, presence: true
      validates :container_id, presence: true

      validate :file_uniqueness, unless: :skip_file_uniqueness

      attr_accessor :skip_file_uniqueness, :current_gid, :current_role_name, :no_access_check

      alias_attribute :container_id, :nfs_store_container_id
    end

    class_methods do
      # Calculate a the MD5 hash for a file focusing on memory efficiency for large files by handling as chunks
      # NOTE: this should not be used directly against mounted archive files that are larger than one chunk,
      # since the overhead of continuous unzipping slows things enormously.
      # @param file_path [String] full path to the file
      # @return [String] MD5 hash
      def hash_for_file(file_path)
        Manage::ContainerFile.hash_for_file file_path
      end

      # Check if file MD5 hash exists in a DB record for this type of upload, stored or archived file
      # @param file_hash [String] MD5 file hash
      # @return [Boolean]
      def exists?(file_hash)
        !!where(file_hash: file_hash).first
      end
    end

    # Analyze the file to complete its attributes
    # @param full_file_path [String] absolute file path to the file to analyze
    def analyze_file!(full_file_path)
      pn = Pathname.new(full_file_path)
      self.file_size = pn.size
      self.file_updated_at = pn.mtime

      if is_a?(NfsStore::Manage::ArchivedFile)
        if file_size < MaxSizeForArchiveFileHash || file_hash.nil?
          self.file_hash = self.class.hash_for_file(full_file_path)
        else
          Rails.logger.warn 'Skipping file hash for large ArchivedFile'
        end
      end

      self.content_type = NfsStore::Utils::MimeType.full_mime_type(full_file_path) || UnknownMimeTypeText
    end

    # Get mime type short text for current file
    def mime_type_text
      mt = MIME::Types[content_type]&.first if content_type.present?

      mt.present? && (mt.friendly || mt.sub_type || mt.media_type) || UnknownMimeTypeText
    end

    # Generate download URL for item
    # @return [String] download URL
    def url
      Rails.application.routes.url_helpers.nfs_store_download_path(id)
    end

    # Find a valid filesystem path for retrieval of the file, based on the first of the user's
    # groups that allows access to it. Returns nil if none match
    # @return [String, Nil] absolute path via mount point, or nil
    def retrieval_path
      file_path = nil
      current_user_role_names.each do |role_name|
        file_path = path_for role_name: role_name
        break if file_path
      end

      file_path
    end

    # All role names that the current user has assigned
    # @return [Array(String)] list of role names
    def current_user_role_names
      container.current_user_role_names
    end

    # All group ID gids that the current user has assigned
    # @return [Array(Integer)] list of gids
    def current_user_group_ids
      container.current_user_group_ids
    end

    # Check if this record has already been stored before attempting to save (or upload) it
    # @return [Boolean]
    def already_stored?
      !file_uniqueness
    end

    #
    # Simply look for stored files that have file_name and path that matches the current file.
    # @return [Boolean]
    def file_matching_path
      !!container.stored_files.where(file_name: file_name, path: path).first
    end

    private

    def path_for(role_name: nil)
      raise FsException::Action, 'role_name must be specified' unless role_name

      ext_path = []
      ext_path << archive_mount_name if respond_to?(:archive_mount_name) && archive_mount_name
      ext_path << path if path

      ext_path_str = nil
      ext_path_str = File.join(ext_path) unless ext_path.empty?

      if !no_access_check && !Manage::Filesystem.test_dir(role_name, container, :read, extra_path: ext_path_str,
                                                                                       file_name: file_name)
        Rails.logger.warn "Role #{role_name} can not access #{container} extra_path: #{ext_path_str}, file_name: #{file_name}"
        return nil
      end
      parts = []
      parts << container.path_for(role_name: role_name)
      parts << archive_mount_name if respond_to?(:archive_mount_name) && archive_mount_name
      parts << path if path.present?
      parts << file_name

      self.current_role_name = role_name
      self.current_gid = Manage::Group.group_id_from_role_name role_name

      File.join(*parts)
    end

    def file_uniqueness
      return unless @file_uniqueness.nil?

      res = container.stored_files.where(file_hash: file_hash, file_name: file_name, path: path).first
      # If a result was found then the file is possibly not unique.
      # To decide, check if the current ID matches the result ID
      # If it doesn't match then the result indicates it is a duplicate
      # If it does match and the result indicates the previous upload was completed then it is a duplicate (only for uploads)
      # Otherwise the result is not a duplicate
      # This works correctly whether the record is persisted or not (no ID set)
      res = (res.id != id) || (respond_to?(:completed) && completed) if res
      @file_uniqueness = !res
      unless @file_uniqueness
        errors.add 'file',
                   'indicates that a file with this content has already been stored in this container. Duplicate files can not be stored.'
        return false
      end
      @file_uniqueness
    end

    def clean_path
      return true if persisted?

      self.path = NfsStore::Manage::Filesystem.clean_path path
    end
  end
end
