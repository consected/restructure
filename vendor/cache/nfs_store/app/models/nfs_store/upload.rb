module NfsStore
  class Upload < NfsStore::UserBase

    include HandlesContainerFile
    include HasCurrentUser

    FinalFilenameSuffix = 'final'.freeze

    scope :completed, ->{ where completed: true }

    validates :chunk_hash, presence: true

    validate :no_unexpected_errors
    validate :was_not_already_completed
    validate :chunk_hash_match
    validate :content_length_match
    validate :upload_allowed?

    after_save :finalize_upload, if: ->{ @ready_to_finalize }

    attr_accessor :upload, :chunk_hash

    # Find an latest upload meeting the provided conditions
    # Raises FsException::Upload if the latest upload was incomplete, but the
    # chunk files for it are inconsistent with what is expected.
    # @param container [Container, Integer] the instance or ID of the container to be uploaded to
    # @param file_hash [String] MD5 hash for the full file to be uploaded
    # @param file_name [String] original filename of the file
    # @param completed [true, false, nil] if not nil filter by whether the upload was completed or not
    # @return [Upload, nil]
    def self.find_upload container, file_hash, file_name, completed: nil, path: nil
      conditions = {container: container, file_hash: file_hash, file_name: file_name}
      conditions[:completed] = completed unless completed.nil?
      path = NfsStore::Manage::Filesystem.clean_path(path)
      conditions[:path] = path

      upload = Upload.where(conditions).order(id: :desc).first
      if upload
        # Validate if the file has already been finalized or would otherwise be invalid
        if upload.already_stored?
          raise FsException::Action.new "A matching stored file already exists"
        end

        unless upload.check_chunk_files
          Rails.logger.warn "Chunk files for an incomplete upload were not present"
          raise FsException::Upload.new "Chunk files for an incomplete upload were not present"
        end

      else
        # Check if a different file with this name has already been uploaded
        conditions.delete :file_hash
        upload = Upload.where(conditions).order(id: :desc).first
        if upload
          raise FsException::FilenameExists.new "A different file with this name already exists. Either rename the file or upload it inside a folder."
        else
          return
        end
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
    def self.init container_id:, file_hash:, file_name:, content_type:, user:, relative_path: nil

      container = Manage::Container.find(container_id)
      #  Ensure the relative path is nil in case it is just an empty string
      relative_path = nil if relative_path.blank? || relative_path == '.'

      begin
        me = find_upload container, file_hash, file_name, completed: false, path: relative_path
      rescue FsException::Upload
        Rails.logger.info "Continuing with a new upload by resetting incomplete chunk files"
        # Cleanup happens in #initialize
      end
      unless me
        # Prepare the fresh upload
        me = Upload.new(container: container, file_hash: file_hash, file_name: file_name, content_type: content_type, user: user, path: relative_path)
      end

      me.container.current_user = user if me

      return me
    end

    # Handle the upload of a chunk
    # @param upload [ActionDispatch::Http::UploadedFile] standard Rails uploaded file object
    # @param headers [Hash] request headers, keyed by case-insensitive strings
    # @param chunk_hash [String] the MD5 hash for this specific chunk
    # @return self
    def consume_chunk upload:, headers:, chunk_hash:
      begin
        return unless was_not_already_completed

        @upload = upload
        @headers = headers
        @chunk_hash = chunk_hash

        raise FsException::Upload.new "No MD5 hash provided for chunk. Can't validate it so the upload won't complete." unless chunk_hash.present?

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
          cleanup_chunk self.chunk_count
          return
        end

        # If this is the only chunk or it is the final one
        # finalize everything
        if !cr || (cr[:to] + 1 == cr[:total])
          # Set completed up front, to allow validations to occur on save
          self.completed = true

          concat_chunks

          tmp_file_size = total_upload_size

          if tmp_file_size == 0
            raise FsException::Upload.new 'Stored file has length zero. This is not correct.'
            return
          end

          # Either a content range was not specified, or it was and indicates this is the last chunk
          # The content length we were told to expect comes from the content-length header if no content-range was specified
          cl = (cr ? cr[:total] : @upload.size)

          @content_length_match = (cl == tmp_file_size)

          unless @content_length_match
            Rails.logger.error "Content length mismatch: #{cl} == #{tmp_file_size} || #{cr} #{@upload.size}"
            raise FsException::Upload.new "Content that we received did not match the length we were told to expect. The upload failed."
          end

          self.file_size = tmp_file_size

          final_hash = hash_for_file

          # Check the final hash we were told to expect and that we have calculated on the file both match
          @final_hash_match = (self.file_hash == final_hash)

          unless @final_hash_match
            raise FsException::Upload.new "The MD5 hash used to check the file consistency did not match what we were told to expect. The upload failed."
          end

          @ready_to_finalize = true

        else
          # We still have other chunks to receive. Keep a running total of the file size we have received so far
          self.file_size = ChunkSize * self.chunk_count
        end

        self
      rescue => e
        cleanup_chunk_files
        @unexpected_error = true
        raise e
      end

    end

    def hash_for_file
      self.class.hash_for_file final_temp_path
    end


    def to_jq_upload
      {
        "name" => self.file_name,
        "size" => self.file_size,
        "hash" => self.file_hash,
        "url" => self.url
      }
    end

    # Get the size of the uploaded file residing in the temp directory
    # @return [Integer, nil] returns the size in bytes or nil if the file does not exist
    def total_upload_size
      if File.exists? final_temp_path
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
      each_chunk_file_path(not_final: true) {|path| num += 1 if File.file?(path) }
      return num == chunk_count
    end


    private

      # Initializing of an upload is performed only by NfsStore::Upload.init
      def initialize options={}
        super
        self.container.current_user = self.user
        raise FsException::NoAccess.new "Container does not allow uploads" unless upload_allowed?
        self.completed ||= false
        self.chunk_count ||= 0

        cleanup_chunk_files
      end

      # Parse the Content-Range header for chunk information
      # @return [Hash{type=>String, from=>Integer, to=>Integer, total=>Integer}]
      def content_range

        cr = @headers['Content-Range']
        return nil unless cr

        res = (/(bytes) (\d+)-(\d+)\/(\d+)/).match(cr)
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
        @upload_chunk = @upload.read
        new_chunk_num = chunk_count + 1
        path = chunk_path new_chunk_num
        FileUtil.rm path if File.exist? path
        File.open(path, "wb") { |f| f.write(@upload_chunk) }
        self.chunk_count = new_chunk_num
      end

      # Generate filename for the chunk that allows all related chunks to be easily identified
      # @param num [Integer] the chunk number being processed
      # @return [String] the long filename representing the unique chunk filename
      def chunk_filename num
        if num.is_a? Integer
          str = "000000000000000#{num}"[-12..-1]
        else
          str = num
        end
        "container-#{self.container.id}--#{self.file_hash}--#{file_name_hash}--uploadchunk-#{str}"
      end

      # Physical path to the chunk temp file
      # @param num [Integer] the chunk number being processed
      # @return [String] full path
      def chunk_path num
        tmp_dir = Manage::Filesystem.temp_directory
        path = File.join(tmp_dir, chunk_filename(num))
      end

      # Final path to the full file after all chunks have been uploaded and concatenated
      # @return [String] full path
      def final_temp_path
        chunk_path(FinalFilenameSuffix)
      end

      # Concatenate all the chunk files, generating the final file
      # Cleanup the chunk files
      def concat_chunks
        begin
          cleanup_chunk FinalFilenameSuffix
          File.open(final_temp_path, 'wb') do |f|
            each_chunk_file_path(not_final: true) do |path|
              data = File.read(path)
              f.write(data)
            end
          end
          cleanup_chunk_files not_final: true
        rescue => e
          cleanup_chunk FinalFilenameSuffix
          raise e
        end
      end

      # Finalize the upload by passing the final complete file to NfsStore::Manage::StoredFile, the
      # class that manages files
      # Cleans up the final temp file
      def finalize_upload

        raise FsException::Upload.new "Upload is invalid. Error: #{errors.first.join(' ')}" unless valid?
        raise FsException::Upload.new "Container user is not set." unless self.container.current_user

        Manage::StoredFile.finalize_upload self, final_temp_path

        cleanup_chunk_files
      end

      # Remove a specific chunk file
      def cleanup_chunk num
        path = chunk_filename(num)
        FileUtils.rm path if File.exists? path
      end

      # Cleanup all chunk files.
      # @param not_final [Boolean] sets whether the 'final' temp file should also be cleaned up, or just the intermediate chunks.
      #   Default: false, cleans up the final file too
      def cleanup_chunk_files not_final: false
        each_chunk_file_path {|path| FileUtils.rm path if File.file?(path) && (!not_final || !path.end_with?("-#{FinalFilenameSuffix}")) }
      end

      # Iterate through the chunk files, yielding to the block with the file path for each
      def each_chunk_file_path not_final: false
        tmp_dir = Manage::Filesystem.temp_directory
        Dir.glob("#{tmp_dir}/#{chunk_filename('*')}").sort.each do |full_file_path|
          yield full_file_path unless not_final && full_file_path.end_with?("-#{FinalFilenameSuffix}")
        end
      end

      # Validate the uploaded chunk hash matches the specified hash
      def chunk_hash_match
        return if self.errors.present?

        if @chunk_hash_match.nil? && @upload_chunk && @chunk_hash
          uploaded_chunk_hash = Digest::MD5.hexdigest(@upload_chunk)
          @chunk_hash_match = (@chunk_hash == uploaded_chunk_hash)
        end

        unless @chunk_hash_match
          self.errors.add :chunk_hash, "of this chunk does not match the MD5 hash the client calculated. This chunk didn't transfer correctly."
          return
        end
        @chunk_hash_match
      end

      # Generating a filename hash allows for clean filenames in the temp directory
      def file_name_hash
        Digest::MD5.hexdigest(self.file_name)
      end

      # Is the upload still in progress?
      # @return [Boolean] meaning true if this upload is still awaiting chunks, and false if the upload was finalized
      def was_not_already_completed
        return if self.errors.present?

        if @was_not_already_completed.nil?
          @was_not_already_completed = !self.completed
        end

        unless @was_not_already_completed
          errors.add :file, 'already exists. Duplicate files can not be added'
          return
        end
        @was_not_already_completed
      end

      # Validates the content length for the completed file matches the header specification
      def content_length_match
        unless @content_length_match || !self.completed
          self.errors.add :content_length, "of the file does not match the content length we were told to expect by the client."
        end
        @content_length_match
      end

      # Validates that the final file MD5 hash matches the hash specified by the client
      def final_hash_match
        unless @final_hash_match
          self.errors.add :file_hash, "of the file does not match the MD5 hash the client calculated. Something didn't transfer correctly."
        end
        @final_hash_match
      end

      # Validates the container allows files to be created in it
      def upload_allowed?
        return unless @check_can_upload.nil?

        unless container.allows_current_user_access_to? :edit
          errors.add :container, "does not allow files to be created"
          @check_can_upload = false
        else
          @check_can_upload = true
        end
        return @check_can_upload
      end

      # Validator for errors caught during processing but outside of validations
      def no_unexpected_errors
        if @unexpected_error
          self.errors.add :unexpected_error, 'occurred during the upload'
        end
        @unexpected_error
      end


  end
end
