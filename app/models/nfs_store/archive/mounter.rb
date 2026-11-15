# frozen_string_literal: true

module NfsStore
  module Archive
    #
    # Provides support for extracting files from archive and compressed files
    # with common archive file extensions. The original archive files are a StoredFile
    # and the resulting extracted files are captured as a set of ArchiveFile records
    # stored in a directory that has a name that matches the original StoredFile, plus
    # a suffix ArchiveMountSuffix.
    #
    # The extraction process is idempotent, and will not re-extract files.
    # Any failures during extraction are captured by flag files in the same directory
    # as the archive file, with special suffixes to indicate processing state.
    #
    # It should be noted that this class is named Mounter, since it originally used
    # a Zip mount approach to access files within zip archives. This was slow and
    # unreliable due to the need to perform subsequent processing of individual ArchivedFiles
    # within the archive, over the networked NFS mount. The current
    # implementation extracts files physically from the archive into a directory.
    class Mounter
      ArchiveExtensions = ['.zip', '.tar', '.gz', '.bz2', '.7z'].freeze

      # Suffix added to archive directories where files are extracted from
      # original stored files with ArchiveExtensions
      ArchiveMountSuffix = '.__mounted-archive__'

      # Suffixes used to indicate various processing states
      ProcessingArchiveSuffix = '.__processing-archive__'
      FailedArchiveSuffix = '.__failed-archive__'
      ProcessingIndexSuffix = '.__processing-index__'

      # Timeout for archive extraction process (in seconds) - 30 minutes
      ExtractionTimeout = 1800
      # Allow automatic retry of processing after this time (timeout + 4 minutes)
      ProcessingRetryTime = ExtractionTimeout + 240

      attr_accessor :stored_file

      def initialize(stored_file: nil)
        self.stored_file = stored_file
        super()
      end

      #
      # Attempt to mount the stored file as an archive
      # @param store_file [NfsStore::Manage::StoredFile]
      def self.mount(stored_file)
        mounter = new
        mounter.stored_file = stored_file
        mounter.mount
      end

      def self.index(stored_file)
        mounter = new
        mounter.stored_file = stored_file
        mounter.index
      end

      # Attempt to mount all stored files from a query
      # @param stored_files [ActiveRecord::Relation] query results for stored files to attempt to mount
      def self.mount_all(stored_files)
        stored_files.all.each do |sf|
          next unless has_archive_extension?(sf)

          # if File.mtime(sf.retrieval_path)
          mounter = new
          mounter.stored_file = sf
          # How old is the file?
          td = begin
            Time.now - File.ctime(sf.retrieval_path)
          rescue StandardError
            nil
          end

          if (td && td < ProcessingRetryTime) || mounter.archive_extracted? # || sf.last_process_name_run == '_all_done_'
            next
          end

          $stderr.puts 'Retrying extract and indexing'
          # Remove the existing flags before restarting
          mounter.extract_completed!
          mounter.index_completed!
          sf.process_new_file
        rescue SystemCallError, IOError => e
          raise_flag_file_error("mount_all for stored file '#{sf&.file_name}' (id: #{sf&.id})",
                                sf&.retrieval_path, e, stored_file: sf)
        end
      end

      # Name of the mounted archive, which is the directory name of the mount point
      # @param archive_file_name [String] the file name of the archive file to be mounted
      # @return [String] the mount point name
      def self.archive_mount_name(archive_file_name)
        return nil unless archive_file_name.present?

        "#{archive_file_name}#{ArchiveMountSuffix}"
      end

      # Remove the directory this file was in, if the directory is now empty
      def self.remove_empty_archive_dir(file_path)
        pn = Pathname.new file_path

        start = true

        while start || !path_is_archive?(file_path)
          start = false
          file_path = pn.dirname.to_s
          pn = Pathname.new file_path

          # We continue if the new path exists (and is accessible),
          # is a directory and is not the base archive path
          return unless pn.exist? && pn.directory? && !path_is_archive?(file_path)

          $stderr.puts "Reset file_path to its directory #{file_path}"

          if pn.empty?
            pn.rmdir
            $stderr.puts "Removed empty archive directory #{file_path}"
          end
        end
      end

      # Check if a path appears to be a mounted archive based on its suffix
      # @param path [String] the path string
      # @return [Boolean]
      def self.path_is_archive?(path)
        return false unless path

        # NOTE: this is invoked with already-resolved absolute filesystem
        # paths (e.g. from `remove_empty_archive_dir`). We do not pass
        # through `Filesystem.clean_path`, which strictly rejects absolute
        # paths and traversal sequences as part of the user-input
        # boundary contract.
        path = path.to_s
        return false if path.blank?

        path.include?(ArchiveMountSuffix)
      end

      def failed_indicator?
        archive_path.to_s.end_with?(FailedArchiveSuffix)
      end

      #
      # Is the #stored_file an indicator that doesn't represent a failure?
      # (we don't want failure indicators to time out)
      # If the:
      # - file didn't exist for some reason - consider it to not be an indicator so return nil
      # - file is a failure indicator that shouldn't time out - return false
      # - indicator hasn't timed out - return false
      # - indicator timed out - return true
      # @param [Boolean] clear - flag that the indicator should be cleaned up if timed out
      # @return [true|false|nil]
      def indicator_timed_out?(clear: false)
        # File is missing - consider it not an indicator and return
        return false unless File.exist?(archive_path)
        # File represents a failure indicator - these don't time out so return false
        return false if failed_indicator?

        if (Time.now - File.mtime(archive_path)) >= ProcessingRetryTime
          # Timed out. Clean up if `clear: true`
          FileUtils.rm_f(archive_path) if clear
          true
        else
          # Indicator hasn't timed out yet
          false
        end
      rescue SystemCallError, IOError => e
        raise_flag_file_error('indicator_timed_out?', archive_path, e)
      end

      # Filename of the flag used to indicate an archive extract is in progress
      # @param archive_file_name [String] the file name of the archive file to be mounted
      # @return [String] the flag filename
      def processing_archive_flag_path
        "#{archive_path}#{ProcessingArchiveSuffix}"
      end

      # Filename of the flag used to indicate an archive extract failed
      # @param archive_file_name [String] the file name of the archive file to be mounted
      # @return [String] the flag filename
      def failed_archive_flag_path
        "#{archive_path}#{FailedArchiveSuffix}"
      end

      #
      # An extract is marked as being in progress with a flag file in the root directory,
      # named with the stored file name and a special extension.
      # If the flag file does NOT exist, then an extract is definitely not in progress.
      # If the flag file does exist, it will be ignored if
      # the modification timestamp of the file is older than
      # the ProcessingRetryTime (initially 30 minutes). The flag file will be removed,
      # and the extract will be consider not in progress.
      # Otherwise an extract status is consider to be in progress.
      # @return [Boolean]
      def extract_in_progress?
        return false unless File.exist?(processing_archive_flag_path)

        if (Time.now - File.mtime(processing_archive_flag_path)) >= ProcessingRetryTime
          extract_completed!
          false
        else
          true
        end
      rescue SystemCallError, IOError => e
        raise_flag_file_error('extract_in_progress?', processing_archive_flag_path, e)
      end

      def extract_in_progress!
        FileUtils.touch(processing_archive_flag_path)
      rescue SystemCallError, IOError => e
        raise_flag_file_error('extract_in_progress!', processing_archive_flag_path, e)
      end

      def extract_failed!(exception)
        extract_completed!
        File.write(failed_archive_flag_path, exception.message)
      rescue SystemCallError, IOError => e
        raise_flag_file_error('extract_failed!', failed_archive_flag_path, e)
      end

      def extract_failure_reason
        return unless File.exist?(archive_path) && archive_path.end_with?(FailedArchiveSuffix)

        File.read(archive_path)
      rescue SystemCallError, IOError => e
        raise_flag_file_error('extract_failure_reason', archive_path, e)
      end

      def extract_completed!
        FileUtils.rm_f(processing_archive_flag_path)
      rescue SystemCallError, IOError => e
        raise_flag_file_error('extract_completed!', processing_archive_flag_path, e)
      end

      def processing_index_flag_path
        "#{archive_path}#{ProcessingIndexSuffix}"
      end

      def index_in_progress?
        File.exist?(processing_index_flag_path) &&
          (Time.now - File.mtime(processing_index_flag_path)) < ProcessingRetryTime
      rescue SystemCallError, IOError => e
        raise_flag_file_error('index_in_progress?', processing_index_flag_path, e)
      end

      def index_in_progress!
        FileUtils.touch(processing_index_flag_path)
      rescue SystemCallError, IOError => e
        raise_flag_file_error('index_in_progress!', processing_index_flag_path, e)
      end

      def index_completed!
        FileUtils.rm_f(processing_index_flag_path)
      rescue SystemCallError, IOError => e
        raise_flag_file_error('index_completed!', processing_index_flag_path, e)
      end

      #
      # Perform the zip extract operation, if possible. This operation is idempotent and
      # only operates on archive files with file names with appropriate file extensions.
      # Any file that doesn't match ArchiveExtensions is skipped.
      # Any file that is already extracted will not be extracted again.
      #
      # The extraction is performed into a local temp directory. If successful, the
      # group ownership is changed to the stored file group id.
      # Then the files are copied into a temporary directory on the network file system
      # using a hidden (dot) directory name.
      # Finally, the complete directory is moved to its final location.
      #
      # @todo
      # Need to check number of files in zip file against number on filesystem after unzip
      # unzip -v zipname.zip | grep 'Defl:N' | wc -l
      def mount
        return :not_archive unless has_archive_extension?
        return if extract_in_progress?

        extract_in_progress!
        pn = Pathname.new(mounted_path)
        Dir.rmdir mounted_path if pn.exist? && pn.empty?
        if pn.exist?
          raise FsException::Action, "Can't unzip - the target directory already exists: #{archive_file_name}"
        end

        unless NfsStore::Manage::Group.group_id_range.include?(stored_file.current_gid)
          raise FsException::Filesystem,
                "Current group specificed in stored archive file is invalid: #{stored_file.current_gid}"
        end

        tpn = Pathname.new(temp_mounted_path)
        FileUtils.rm_rf temp_mounted_path if tpn.exist?
        dir = File.join(Manage::Filesystem.temp_directory, "__filestore__#{SecureRandom.hex}")
        FileUtils.mkdir_p dir

        tmpzipdir = "#{dir}/zip"
        FileUtils.mkdir_p tmpzipdir

        cmd = ['app-scripts/extract_archive.sh', archive_path, tmpzipdir]
        res = Kernel.system(*cmd)
        raise FsException::Action, "Failed to unzip the archive file: #{archive_file_name}" unless res

        FileUtils.chown_R nil, stored_file.current_gid.to_i, tmpzipdir
        FileUtils.cp_r tmpzipdir, temp_mounted_path

        begin
          FileUtils.mv temp_mounted_path, mounted_path
          FileUtils.rm_rf dir
        rescue StandardError => e
          begin
            FileUtils.rm_rf temp_mounted_path
            FileUtils.rm_rf mounted_path
          rescue StandardError => e2
            raise FsException::Action,
                  "Failed to move the extracted archive files and remove the mounted path for: #{archive_file_name}\n" \
                  "#{e}\n#{e2}"
          end
          raise FsException::Action, "Failed to move the extracted archive files: #{archive_file_name}\n#{e}"
        end

        extract_completed! if res
        res
      rescue FsException::Action, StandardError => e
        extract_failed! e
        raise
      end

      #
      # The directory path that the extracted files will be found in
      # @return [String | nil]
      def mounted_path
        return unless archive_path

        @mounted_path ||= "#{archive_path}#{ArchiveMountSuffix}"
      end

      #
      # The temporary directory in the container on the network file system that files
      # are extracted to, before being moved to the location of #mounted_path.
      # The directory name is a hidden (dot) name, so it won't appear to a user
      # until the files are eventually moved to the final location.
      # @return [String]
      def temp_mounted_path
        mounted_path.sub("#{archive_file_name}#{ArchiveMountSuffix}", ".tmp-#{archive_file_name}#{ArchiveMountSuffix}")
      end

      #
      # The path to the stored compressed file
      # @return [String]
      def archive_path
        @archive_path ||= stored_file.retrieval_path
      end

      #
      # File name of the stored compressed file
      # @return [String]
      def archive_file_name
        @archive_file_name ||= stored_file.file_name
      end

      #
      # Number of files extracted from the compressed archive
      # @return [Integer]
      def archive_file_count
        Dir.glob('*', base: mounted_path).length
      end

      # Check the stored file has an archive file extension that matches files we want to mount
      # @return [Boolean]
      def has_archive_extension?
        self.class.has_archive_extension? stored_file
      end

      # Check the stored file passed as an attribute has an archive file extension that matches files we want to mount
      # @return [Boolean]
      def self.has_archive_extension?(stored_file)
        stored_file.file_name.end_with?(*ArchiveExtensions)
      end

      # Check if the archive has been extracted to ArchiveFile database records
      # @return [True, False, Symbol(:in_progress)]
      #   true if the archive has been extracted leading to at least one entry in the database
      #   false if the archive has not been extracted
      #   :in_progess if the current request is in progress
      def archive_extracted?
        return @archive_extracted unless @archive_extracted.nil?

        @archive_extracted = NfsStore::Manage::ArchivedFile.extracted? stored_file: stored_file
      end

      def index
        index_in_progress!
        res = extract_archived_files
        index_completed! if res
      end

      def self.move_to_new_path(file, to_path)
        from_path = file.path

        # If this is the base archive folder, we must ensure the new name reflects this
        to_path = "#{to_path}#{ArchiveMountSuffix}" if path_is_archive?(from_path) && !path_is_archive?(arch_to_path)

        file.move_to to_path
      end

      # Raise a descriptive FsException::Action when a flag file operation fails
      # due to a filesystem error (e.g. permission denied, I/O error).
      # The message includes the method name, the flag file path, the original
      # error details, user context, and a hint about likely causes.
      # Defined as a class method so both instance and class methods (e.g. mount_all) can use it.
      # @param method_name [String] the name of the method that failed
      # @param flag_path [String] the path to the flag file that caused the error
      # @param original_error [Exception] the original filesystem error
      # @param stored_file [NfsStore::Manage::ContainerFile, nil] the stored file associated with the failure
      # @raise [FsException::Action]
      def self.raise_flag_file_error(method_name, flag_path, original_error, stored_file: nil)
        raise FsException::Action,
              "#{method_name} failed for flag file '#{flag_path}': " \
              "#{original_error.class} - #{original_error.message}. " \
              "#{stored_file_user_context(stored_file)}" \
              'This may indicate a filesystem mount/connection issue, or that the current user ' \
              "does not have access to the container's files through the available roles. " \
              "Original backtrace: #{original_error.short_string_backtrace}"
      end
      private_class_method :raise_flag_file_error

      # Format user context from a stored file for inclusion in error messages.
      # Returns an empty string if the stored file is nil or context cannot be retrieved.
      # @param stored_file [NfsStore::Manage::ContainerFile, nil]
      # @return [String]
      def self.stored_file_user_context(stored_file)
        return '' unless stored_file

        cu = stored_file.container&.current_user
        'Stored file user context - ' \
          "role_names: #{stored_file.current_user_role_names}, " \
          "current_user_id: #{cu&.id}, " \
          "current_user_email: #{cu&.email}, " \
          "app_type_id: #{cu&.app_type_id}. "
      rescue StandardError
        ''
      end
      private_class_method :stored_file_user_context

      private

      # Instance-level delegate to the class method, automatically injecting the stored_file
      # so all instance rescue blocks include user context without modification
      def raise_flag_file_error(method_name, flag_path, original_error)
        self.class.send(:raise_flag_file_error, method_name, flag_path, original_error, stored_file:)
      end

      # Extract files from an archive and add them to the database in a single bulk import
      # @return [Boolean] result true if all the archived files were extracted and stored
      def extract_archived_files
        unless Rails.env.test?
          msg = "Start to extract files? (archive not extracted? #{!archive_extracted?}) to DB for #{mounted_path}"
          $stderr.puts msg

          unless mounted_path&.present?
            Rails.logger.warn msg
            Rails.logger.warn "extract_archived_files: mounted_path is nil for #{stored_file}" \
                              "role names: #{stored_file&.current_user_role_names} " \
                              "container: #{stored_file&.container&.id}" \
                              "current_user: #{stored_file&.container&.current_user&.email}"
            return false
          end
        end

        result = true
        return true if archive_extracted?

        NfsStore::Manage::ArchivedFile.transaction do
          start_time = Time.now
          iterations = 0
          failures = 0

          # Check if mounted_path exists before attempting to glob
          unless mounted_path&.present? && File.directory?(mounted_path)
            Rails.logger.warn "Mounted path is nil or does not exist: #{mounted_path.inspect}"
            return false
          end

          glob_path = "#{mounted_path}/**/*"
          %w([ ] { } ?).each do |c|
            glob_path = glob_path.gsub(c, "\\#{c}")
          end

          files = Dir.glob(glob_path)

          $stderr.puts "Starting extract_archived_files of #{files.length} files" unless Rails.env.test?

          container = stored_file.container

          unless stored_file.current_role_name
            Rails.logger.warn 'stored_file.current_role_name is nil - the following operations may fail'
          end

          all_afs = []
          files.each do |f|
            pn = Pathname.new f
            unless pn.directory?
              begin
                # Don't use regex - it breaks with special characters
                archived_file_path = pn.dirname.to_s.sub("#{mounted_path}/", '').sub(mounted_path.to_s, '')
                afval = stored_file.path ? File.join(stored_file.path, archive_file_name) : archive_file_name
                af = NfsStore::Manage::ArchivedFile.new container: container,
                                                        path: archived_file_path,
                                                        archive_file: afval,
                                                        file_name: pn.basename,
                                                        nfs_store_stored_file_id: stored_file.id

                af.current_user ||= stored_file.user_id
                af.send :write_attribute, :user_id, stored_file.user_id
                container.current_user ||= stored_file.user_id
                af.current_role_name = stored_file.current_role_name
                af.current_gid = stored_file.current_gid
                af.no_access_check = true
                af.analyze_file!
                all_afs << af
              rescue StandardError => e
                failures += 1
                Rails.logger.warn "Failure (#{failures}) during extract_archived_files. #{e}"
                Rails.logger.warn e.short_string_backtrace
                # Continue on to the next one.
              end
            end
            iterations += 1
            next unless Time.now - start_time > ExtractionTimeout

            Rails.logger.warn "Timeout in extract_archived_files after #{iterations} iterations, " \
                              "with #{failures} failures."
            result = false
            raise ActiveRecord::Rollback
          end

          result = NfsStore::Manage::ArchivedFile.import(all_afs, validate: false) && result

          # It is possible that repeated or overlapping background processes lead to double entries in the archive_files
          # table. To fix this it is fastest to complete the import, then remove the duplicates.

          NfsStore::Manage::ArchivedFile.remove_duplicates(archive_file_name, stored_file.id)
        end

        result
      end

      # end private
    end
  end
end
