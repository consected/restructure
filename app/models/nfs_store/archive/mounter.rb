# frozen_string_literal: true

module NfsStore
  module Archive
    class Mounter
      ArchiveExtensions = ['.zip', '.tar', '.gz', '.bz2', '.7z'].freeze
      ArchiveMountSuffix = '.__mounted-archive__'
      ProcessingArchiveSuffix = '.__processing-archive__'
      ProcessingIndexSuffix = '.__processing-index__'
      MountPerms = '227'
      ExtractionTimeout = 1800
      ProcessingRetryTime = ExtractionTimeout + 240
      attr_accessor :stored_file

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

          if (td && td < ProcessingRetryTime) || mounter.archive_extracted? || sf.last_process_name_run == '_all_done_'
            next
          end

          puts 'Retrying extract and indexing'
          mounter.extract_completed!
          mounter.index_completed!
          sf.process_new_file
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

          puts "Reset file_path to its directory #{file_path}"

          if pn.empty?
            pn.rmdir
            puts "Removed empty archive directory #{file_path}"
          end
        end
      end

      # Check if a path appears to be a mounted archive based on its suffix
      # @param path [String] the path string
      # @return [Boolean]
      def self.path_is_archive?(path)
        return unless path

        path = NfsStore::Manage::Filesystem.clean_path(path)
        return unless path

        path.end_with? ArchiveMountSuffix
      end

      # Filename of the flag used to indicate an archive extract is in progress
      # @param archive_file_name [String] the file name of the archive file to be mounted
      # @return [String] the flag filename
      def processing_archive_flag_path
        "#{stored_file.retrieval_path}#{ProcessingArchiveSuffix}"
      end

      def extract_in_progress?
        File.exist?(processing_archive_flag_path) &&
          (Time.now - File.mtime(processing_archive_flag_path)) < ProcessingRetryTime
      end

      def extract_in_progress!
        FileUtils.touch(processing_archive_flag_path)
      end

      def extract_completed!
        FileUtils.rm_f(processing_archive_flag_path)
      end

      def processing_index_flag_path
        "#{stored_file.retrieval_path}#{ProcessingIndexSuffix}"
      end

      def index_in_progress?
        File.exist?(processing_index_flag_path) &&
          (Time.now - File.mtime(processing_index_flag_path)) < ProcessingRetryTime
      end

      def index_in_progress!
        FileUtils.touch(processing_index_flag_path)
      end

      def index_completed!
        FileUtils.rm_f(processing_index_flag_path)
      end

      # Perform the mount operation, if possible. This operation is idempotent and
      # only operates on archive files with file names with appropriate file extensions.
      # Any file that doesn't match ArchiveExtensions is skipped.
      # Any file that is already mounted will not be mounted again.
      def mount
        res = true

        return unless has_archive_extension?

        return if extract_in_progress?

        extract_in_progress!

        @archive_path = stored_file.retrieval_path
        @mounted_path = "#{@archive_path}#{ArchiveMountSuffix}"
        @archive_file = stored_file.file_name

        pn = Pathname.new(@mounted_path)

        if pn.exist?
          if pn.empty?
            puts "Removing the empty directory which appears at #{@mounted_path}"
            Dir.rmdir @mounted_path
          else
            puts "The directory is not empty at #{@mounted_path}"
          end
        end

        unless pn.exist?
          unless NfsStore::Manage::Group.group_id_range.include?(stored_file.current_gid)
            raise FsException::Filesystem,
                  "Current group specificed in stored archive file is invalid: #{stored_file.current_gid}"
          end

          dir = File.join(Manage::Filesystem.temp_directory, "__filestore__#{SecureRandom.hex}")

          FileUtils.mkdir_p dir

          tmpzipdir = "#{dir}/zip"
          FileUtils.mkdir tmpzipdir
          cmd = ['unzip', @archive_path, '-d', tmpzipdir]

          res = Kernel.system(*cmd)
          puts "Command: #{cmd}\nRes: #{res}"
          raise FsException::Action, "Failed to unzip the archive file: #{@archive_path}" unless res

          puts "Setting permissions (gid=#{stored_file.current_gid.to_i}) on #{tmpzipdir}"

          FileUtils.chown_R nil, stored_file.current_gid.to_i, tmpzipdir

          # Need to check number of files in zip file against number on filesystem after unzip
          # unzip -v zipname.zip | grep 'Defl:N' | wc -l
          # find zipname.zip.__mounted-archive__ -type f -print | wc -l
          #

          puts "Copying #{tmpzipdir} to #{@mounted_path}"
          FileUtils.cp_r tmpzipdir, @mounted_path
          puts 'Cleaning directory'
          FileUtils.rm_rf dir
          puts "Done with #{@mounted_path}"

        end

        extract_completed! if res
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

        @archive_file ||= stored_file.file_name
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

      private

      # Extract files from an archive and add them to the database in a single bulk import
      # @return [Boolean] result true if all the archived files were extracted and stored
      def extract_archived_files
        @archive_path = stored_file.retrieval_path
        @mounted_path = "#{@archive_path}#{ArchiveMountSuffix}"
        @archive_file = stored_file.file_name
        puts "Start to extract files? (archive not extracted? #{!archive_extracted?}) to DB for #{@mounted_path}"

        result = true
        return true if archive_extracted?

        NfsStore::Manage::ArchivedFile.transaction do
          start_time = Time.now
          iterations = 0
          failures = 0

          glob_path = "#{@mounted_path}/**/*"
          %w([ ] { } ?).each do |c|
            glob_path = glob_path.gsub(c, "\\#{c}")
          end

          files = Dir.glob(glob_path)

          puts "Starting extract_archived_files of #{files.length} files"

          container = stored_file.container

          all_afs = []
          files.each do |f|
            pn = Pathname.new f
            unless pn.directory?
              begin
                # Don't use regex - it breaks with special characters
                archived_file_path = pn.dirname.to_s.sub("#{@mounted_path}/", '').sub(@mounted_path.to_s, '')
                afval = stored_file.path ? File.join(stored_file.path, @archive_file) : @archive_file
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
                Rails.logger.warn "Failure (#{failures}) during extract_archived_files. #{e}\n#{e.backtrace.join("\n")}"
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
        end

        result
      end

      # end private
    end
  end
end
