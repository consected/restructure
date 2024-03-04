# frozen_string_literal: true

module NfsStore
  class Upload < NfsStoreUserBase
    self.table_name = 'nfs_store_uploads'

    include HandlesContainerFile
    include HasCurrentUser

    FinalFilenameSuffix = 'final'

    # An optional association with stored_file.
    # It must be optional, since we can't set the stored_file
    # until after the upload has completed.
    belongs_to :stored_file,
               class_name: 'NfsStore::Manage::StoredFile',
               foreign_key: 'nfs_store_stored_file_id',
               optional: true

    scope :completed, -> { where completed: true }

    validates :chunk_hash, presence: true
    validates :upload_set, presence: true

    validate :no_unexpected_errors
    validate :was_not_already_completed
    validate :chunk_hash_match
    validate :content_length_match
    validate :upload_allowed?

    before_save :finalize_upload, if: -> { @ready_to_finalize }

    attr_accessor :upload, :chunk_hash

    # Find an latest upload meeting the provided conditions
    # Raises FsException::Upload if the latest upload was incomplete, but the
    # chunk files for it are inconsistent with what is expected.
    # @param container [Container, Integer] the instance or ID of the container to be uploaded to
    # @param file_hash [String] MD5 hash for the full file to be uploaded
    # @param file_name [String] original filename of the file
    # @param completed [true, false, nil] if not nil filter by whether the upload was completed or not
    # @return [Upload, nil]
    def self.find_upload(container, file_hash, file_name, user, completed: nil, path: nil)
      conditions = { container: container, file_hash: file_hash, file_name: file_name }
      conditions[:completed] = completed unless completed.nil?
      path = NfsStore::Manage::Filesystem.clean_path(path)
      conditions[:path] = path

      # Test the container is accessible
      Browse.open_container(id: container, user: user)

      uploads = Upload.where(conditions).order(id: :desc)
      upload = uploads.first
      if upload
        # Validate if the file has already been finalized or would otherwise be invalid
        raise FsException::Action, 'A matching stored file already exists' if upload.already_stored?

        unless upload.check_chunk_files
          upload.cleanup_chunk_files
          uploads.update_all(path: ".failed-upload/#{upload.path}")
          upload.chunk_count = 0
          upload.file_size = 0
          unless upload.check_chunk_files
            Rails.logger.warn 'Chunk files for an incomplete upload were not present'
            raise FsException::Upload, 'Chunk files for an incomplete upload were not present'
          end
        end

      else
        # Check if a different file with this name has already been uploaded
        conditions.delete :file_hash
        upload = Upload.where(conditions).order(id: :desc).first
        return unless upload&.file_matching_path

        raise FsException::FilenameExists,
              'A different file with this name already exists. Either rename the file or upload it inside a folder.'

      end

      # It is necessary to loosely check the stored files if no upload was found, or a completed upload was found
      # (not incomplete uploads, as we are using these for additional chunks and they can't have been moved / renamed)
      # This ensure that a file was not renamed or trashed after completion
      # We can't just check the stored file association, since it is possible that this file had its name changed
      # and another file's name was changed to match this one.
      if !upload || upload.completed
        sf = NfsStore::Manage::StoredFile.where(container: container, file_name: file_name, path: path).first
        # If a matching stored file was found use its referenced upload
        upload = sf.upload if sf
      end

      upload
    end

    # Initialize data for a upload of a chunk
    # Will either pick an existing upload to this container, or will create a new upload
    # @param container_id [Integer] the ID of the container to be uploaded to
    # @param file_hash [String] MD5 digest for the complete file
    # @param content_type [String] MIME type for the file
    # @param user [User] the current user performing the upload
    # @return [Upload] the existing or new Upload object
    def self.init(container_id:, file_hash:, file_name:, content_type:, user:, upload_set:, relative_path: nil)
      container = Browse.open_container(id: container_id, user: user)
      #  Ensure the relative path is nil in case it is just an empty string
      relative_path = nil if relative_path.blank? || relative_path == '.'

      begin
        me = find_upload container, file_hash, file_name, user, completed: false, path: relative_path
      rescue FsException::Upload
        Rails.logger.info 'Continuing with a new upload by resetting incomplete chunk files'
        # Cleanup happens in #initialize
      end
      me ||= Upload.new(container: container, file_hash: file_hash, file_name: file_name, content_type: content_type,
                        user: user, path: relative_path, upload_set: upload_set)

      me.container.current_user = user if me

      me
    end

    # Handle the upload of a chunk
    # @param upload [ActionDispatch::Http::UploadedFile] standard Rails uploaded file object
    # @param headers [Hash] request headers, keyed by case-insensitive strings
    # @param chunk_hash [String] the MD5 hash for this specific chunk
    # @return self
    def consume_chunk(upload:, headers:, chunk_hash:)
      return unless was_not_already_completed

      @upload = upload
      @headers = headers
      @chunk_hash = chunk_hash

      unless chunk_hash.present?
        raise FsException::Upload, "No MD5 hash provided for chunk. Can't validate it so the upload won't complete."
      end

      # If no content range specified, or it was marked as starting from 0
      # then this is the first chunk. Cleanup anything else that may have been
      # floating around for this file upload from previous attempts
      cr = content_range
      if !cr || cr[:from] == 0
        cleanup_chunk_files
        self.chunk_count = 0
      end

      store_chunk

      unless chunk_hash_match
        cleanup_chunk chunk_count
        return
      end

      # If this is the only chunk or it is the final one
      # finalize everything
      if !cr || (cr[:to] + 1 == cr[:total])
        # Set completed up front, to allow validations to occur on save
        self.completed = true

        concat_chunks

        tmp_file_size = total_upload_size

        raise FsException::Upload, 'Stored file has length zero. This is not correct.' if tmp_file_size == 0

        # Either a content range was not specified, or it was and indicates this is the last chunk
        # The content length we were told to expect comes from the content-length
        # header if no content-range was specified
        cl = (cr ? cr[:total] : @upload.size)

        @content_length_match = (cl == tmp_file_size)

        unless @content_length_match
          Rails.logger.error "Content length mismatch: #{cl} == #{tmp_file_size} || #{cr} #{@upload.size}"
          raise FsException::Upload,
                'Content that we received did not match the length we were told to expect. The upload failed.'
        end

        self.file_size = tmp_file_size

        final_hash = hash_for_file

        # Check the final hash we were told to expect and that we have calculated on the file both match
        @final_hash_match = (file_hash == final_hash)

        unless @final_hash_match
          raise FsException::Upload,
                'The MD5 hash used to check the file consistency did not match ' \
                'what we were told to expect. The upload failed.'
        end

        @ready_to_finalize = true

      elsif cr[:to] + 1 > cr[:total]
        raise FsException::Upload,
              "The chunk range uploaded exceeded the size of the original file : #{cr[:to] + 1} > #{cr[:total]}"
      else
        # We still have other chunks to receive. Keep a running total of the file size we have received so far
        self.file_size = ChunkSize * chunk_count
      end

      self
    rescue StandardError => e
      cleanup_chunk_files
      @unexpected_error = true
      raise e
    end

    def hash_for_file
      self.class.hash_for_file final_temp_path
    end

    def to_jq_upload
      {
        'name' => file_name,
        'size' => file_size,
        'hash' => file_hash,
        'url' => url,
        'id' => id
      }
    end

    # Get the size of the uploaded file residing in the temp directory
    # @return [Integer, nil] returns the size in bytes or nil if the file does not exist
    def total_upload_size
      if File.exist? final_temp_path
        File.size(final_temp_path)
      else
        Rails.logger.warn "File does not exist when checking total upload size: #{final_temp_path}"
      end
    end

    # Check chunk files are correct for previous chunk uploads
    # Especially important for resuming uploads
    # @return [Boolean]
    def check_chunk_files
      num = 0
      each_chunk_file_path(not_final: true) { |path| num += 1 if File.file?(path) }
      num == chunk_count
    end

    def self.filters_allow_upload?(file_name, path, container)
      f = "#{path}/#{file_name}".gsub(%r{//+}, '/')
      f = "/#{f}" unless f.start_with? '/'
      NfsStore::Filter::Filter.evaluate f, container
    end

    def self.valid_filters(item_or_container)
      NfsStore::Filter::Filter.filters_for(item_or_container)
    end

    # Cleanup all chunk files.
    # @param not_final [Boolean] sets whether the 'final' temp file should also
    #                            be cleaned up, or just the intermediate chunks.
    #   Default: false, cleans up the final file too
    def cleanup_chunk_files(not_final: false)
      each_chunk_file_path do |path|
        FileUtils.rm path if File.file?(path) && (!not_final || !path.end_with?("-#{FinalFilenameSuffix}"))
      end
    end

    private

    # Initializing of an upload is performed only by NfsStore::Upload.init
    def initialize(options = {})
      super
      container.current_user = user
      raise FsException::NoAccess, 'Container does not allow uploads' unless upload_allowed?

      self.completed ||= false
      self.chunk_count ||= 0

      cleanup_chunk_files
    end

    # Parse the Content-Range header for chunk information
    # @return [Hash{type=>String, from=>Integer, to=>Integer, total=>Integer}]
    def content_range
      cr = @headers['Content-Range']
      return nil unless cr

      res = %r{(bytes) (\d+)-(\d+)/(\d+)}.match(cr)
      return nil unless res && res.length == 5

      {
        type: res[1],
        from: res[2]&.to_i,
        to: res[3]&.to_i,
        total: res[4]&.to_i
      }
    end

    # Store the uploaded chunk
    # Relies on the @upload attribute for the file to be read
    # @return [Integer] number of chunks uploaded so far
    def store_chunk
      # @upload_chunk = @upload.read
      new_chunk_num = chunk_count + 1
      @chunk_path = chunk_path new_chunk_num
      FileUtil.rm @chunk_path if File.exist? @chunk_path
      # Efficiently copy from upload IO to chunk path without consuming too much memory
      IO.copy_stream(@upload, @chunk_path)
      self.chunk_count = new_chunk_num
    end

    # Generate filename for the chunk that allows all related chunks to be easily identified
    # @param num [Integer] the chunk number being processed
    # @return [String] the long filename representing the unique chunk filename
    def chunk_filename(num)
      str = if num.is_a? Integer
              "000000000000000#{num}"[-12..]
            else
              num
            end
      "container-#{container.id}--#{file_hash}--#{file_name_hash}--uploadchunk-#{str}"
    end

    # Physical path to the chunk temp file
    # @param num [Integer] the chunk number being processed
    # @return [String] full path
    def chunk_path(num)
      tmp_dir = Manage::Filesystem.temp_directory
      File.join(tmp_dir, chunk_filename(num))
    end

    # Final path to the full file after all chunks have been uploaded and concatenated
    # @return [String] full path
    def final_temp_path
      chunk_path(FinalFilenameSuffix)
    end

    # Concatenate all the chunk files, generating the final file
    # If there is only one chunk file just move it, since API
    # uploads may send one massive chunk
    # Cleanup the chunk files
    def concat_chunks
      cleanup_chunk FinalFilenameSuffix

      if self.chunk_count == 1
        each_chunk_file_path(not_final: true) do |path|
          FileUtils.mv path, final_temp_path
          break
        end
      else
        File.open(final_temp_path, 'wb') do |f|
          each_chunk_file_path(not_final: true) do |path|
            # User copy_stream to efficiently copy from source path to open destination file
            IO.copy_stream(path, f)
          end
        end
      end

      cleanup_chunk_files not_final: true
    rescue StandardError => e
      cleanup_chunk FinalFilenameSuffix
      raise e
    end

    # Finalize the upload by passing the final complete file to NfsStore::Manage::StoredFile, the
    # class that manages files
    # Cleans up the final temp file
    def finalize_upload
      raise FsException::Upload, "Upload is invalid. Error: #{errors.first}" unless valid?
      raise FsException::Upload, 'Container user is not set.' unless container.current_user

      self.stored_file = Manage::StoredFile.finalize_upload self, final_temp_path

      cleanup_chunk_files
    end

    # Remove a specific chunk file
    def cleanup_chunk(num)
      path = chunk_filename(num)
      FileUtils.rm path if File.exist? path
    end

    # Iterate through the chunk files, yielding to the block with the file path for each
    def each_chunk_file_path(not_final: false)
      tmp_dir = Manage::Filesystem.temp_directory
      Dir.glob("#{tmp_dir}/#{chunk_filename('*')}").sort.each do |full_file_path|
        yield full_file_path unless not_final && full_file_path.end_with?("-#{FinalFilenameSuffix}")
      end
    end

    # Validate the uploaded chunk hash matches the specified hash
    def chunk_hash_match
      return if errors.present?

      if @chunk_hash_match.nil? && @chunk_path && @chunk_hash
        # Calculate MD5 in memory efficient chunks directly from the file
        md5 = Digest::MD5.new
        md5 = md5.file(@chunk_path)
        uploaded_chunk_hash = md5.hexdigest
        @chunk_hash_match = (@chunk_hash == uploaded_chunk_hash)
      end

      unless @chunk_hash_match
        errors.add :chunk_hash,
                   'of this chunk does not match the MD5 hash the ' \
                   "client calculated. This chunk didn't transfer correctly."
        return
      end
      @chunk_hash_match
    end

    # Generating a filename hash allows for clean filenames in the temp directory
    def file_name_hash
      Digest::MD5.hexdigest(file_name)
    end

    # Is the upload still in progress?
    # @return [Boolean] meaning true if this upload is still awaiting chunks, and false if the upload was finalized
    def was_not_already_completed
      return if errors.present?

      @was_not_already_completed = !self.completed if @was_not_already_completed.nil?

      unless @was_not_already_completed
        errors.add :file, 'already exists. Duplicate files can not be added'
        return
      end
      @was_not_already_completed
    end

    # Validates the content length for the completed file matches the header specification
    def content_length_match
      unless @content_length_match || !self.completed
        errors.add :content_length,
                   'of the file does not match the content length we were told to expect by the client.'
      end
      @content_length_match
    end

    # Validates that the final file MD5 hash matches the hash specified by the client
    def final_hash_match
      unless @final_hash_match
        errors.add :file_hash,
                   "of the file does not match the MD5 hash the client calculated. Something didn't transfer correctly."
      end
      @final_hash_match
    end

    # Validates the container allows files to be created in it
    def upload_allowed?
      return unless @check_can_upload.nil?

      if container.allows_current_user_access_to? :edit
        @check_can_upload = true
      else
        errors.add :container, 'does not allow files to be created'
        @check_can_upload = false
      end
      @check_can_upload
    end

    # Validator for errors caught during processing but outside of validations
    def no_unexpected_errors
      errors.add :unexpected_error, 'occurred during the upload' if @unexpected_error
      @unexpected_error
    end
  end
end
