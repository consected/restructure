module NfsStore
  module Archive
    class Mounter

      ArchiveExtensions = ['.zip', '.tar', '.gz', '.bz2'].freeze
      ArchiveMountSuffix = '.__mounted-archive__'
      MountPerms = '227'
      ExtractionTimeout = 30
      attr_accessor :stored_file


      # Attempt to mount the stored file as an archive
      # @param store_file [NfsStore::Manage::StoredFile]
      def self.mount stored_file
        mounter = self.new
        mounter.stored_file = stored_file
        mounter.mount
      end

      # Attempt to mount all stored files from a query
      # @param stored_files [ActiveRecord::Relation] query results for stored files to attempt to mount
      def self.mount_all stored_files
        stored_files.all.each do |sf|
          self.mount sf
        end
      end

      # Name of the mounted archive, which is the directory name of the mount point
      # @param archive_file_name [String] the file name of the archive file to be mounted
      # @return [String] the mount point name
      def self.archive_mount_name archive_file_name
        return nil unless archive_file_name
        "#{archive_file_name}#{ArchiveMountSuffix}"
      end

      # Check if a path appears to be a mounted archive based on its suffix
      # @param path [String] the path string
      # @return [Boolean]
      def self.path_is_archive? path
        return unless path
        NfsStore::Manage::Filesystem.clean_path(path).end_with? ArchiveMountSuffix
      end

      # Perform the mount operation, if possible. This operation is idempotent and
      # only operates on archive files with file names with appropriate file extensions.
      # Any file that doesn't match ArchiveExtensions is skipped.
      # Any file that is already mounted will not be mounted again.
      # Regardless, an attempt will be made to extract archive files to the DB if an
      # archive file was already, or has just been mounted.
      def mount
        if stored_file.file_name.end_with?(*ArchiveExtensions)

          @archive_path = stored_file.retrieval_path
          @mounted_path = "#{@archive_path}#{ArchiveMountSuffix}"
          @archive_file = stored_file.file_name

          pn = Pathname.new(@mounted_path)
          FileUtils.mkdir_p @mounted_path unless pn.exist?
          unless pn.mountpoint?
            cmd = ["archivemount", "-oumask=#{MountPerms},gid=#{stored_file.current_gid},readonly", @archive_path, @mounted_path]
            Rails.logger.info "Command: #{cmd}"
            res = Kernel.system(*cmd)
            raise FsException::Action.new "Failed to mount the archive file: #{@archive_path}" unless res

          end

          extract_archived_files
        end
      end


      private

        # Check if the archive has been extracted to ArchiveFile database records
        # @return [True, False, Symbol(:in_progress)]
        #   true if the archive has been extracted leading to at least one entry in the database
        #   false if the archive has not been extracted
        #   :in_progess if the current request is in progress
        # @todo - resolve race condition on separate requests by making a db entry or filesystem entry?
        def archive_extracted?
          return @archive_extracted unless @archive_extracted.nil?
          @archive_extracted = NfsStore::Manage::ArchivedFile.extracted? stored_file.container, stored_file.path, @archive_file
        end

        # Extract files from an archive and add them to the database in a single bulk import
        def extract_archived_files

          unless archive_extracted?
            start_time = Time.now
            iterations = 0
            failures = 0
            # prevent from another call attempting this while it is in progress - does not protect against multiple
            # users accidentally doing this
            @archive_extracted = :in_progress

            files = Dir.glob("#{@mounted_path}/**/*")

            Rails.logger.info "Starting extract_archived_files of #{files.length} files"

            container = stored_file.container

            all_afs = []
            files.each do |f|
              pn = Pathname.new f
              unless pn.directory?
                begin
                  # Don't use regex - it breaks with special characters
                  archived_file_path = pn.dirname.to_s.sub("#{@mounted_path}/", '').sub("#{@mounted_path}", '')
                  af = NfsStore::Manage::ArchivedFile.new container: container,
                    path: archived_file_path,
                    archive_file: stored_file.path ? File.join(stored_file.path, @archive_file) : @archive_file,
                    file_name: pn.basename
                  container.current_user ||= stored_file.user_id
                  af.current_role_name = stored_file.current_role_name
                  af.current_gid = stored_file.current_gid
                  af.no_access_check = true
                  af.analyze_file!
                  all_afs << af
                  af = nil
                rescue => e
                  failures += 1
                  Rails.logger.warn "Failure (#{failures}) during extract_archived_files. #{e}\n#{e.backtrace.join("\n")}"
                  # Continue on to the next one.
                end
              end
              iterations += 1
              if Time.now - start_time > ExtractionTimeout
                Rails.logger.warn "Timeout in extract_archived_files after #{iterations} iterations, with #{failures} failures."
                break
              end
            end

            res = NfsStore::Manage::ArchivedFile.import all_afs, validate: false
            @archive_extracted = res
          end
        end

      # end private

    end
  end
end
