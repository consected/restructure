require_dependency 'zip'

module NfsStore
  module Archive
    class ZipFileGenerator

      ZipTempFilePrefix = 'nfs_store_download_zipfile'

      # Use the specified temp directory to ensure that it is not sitting on in-memory TempFs
      # @param [String] path to initialized temp directory
      def self.tmpdir
        NfsStore::Manage::Filesystem.temp_directory
      end

      # Create a zip file based on a list of retrieve items (stored and archived files)
      # @param target_path [String, nil] optional destination path, used by prepared downloads
      # @return [Tempfile, String] temp file object or the requested destination path
      def self.zip_retrieved_items(retrieved_items, target_path: nil)
        temp_file = target_path ? nil : Tempfile.new([ZipTempFilePrefix, '.zip'], tmpdir)
        zip_path = target_path || temp_file.path
        FileUtils.mkdir_p(File.dirname(zip_path)) if target_path

        Zip::File.open(zip_path, create: true, compression_level: Zlib::BEST_SPEED) do |zip|
          retrieved_items.each do |f|
            parts = []
            if f[:parent_name].present?
              psd_parts = f[:parent_name].split('/').reject(&:blank?)
              parts += psd_parts
            end
            parts << f[:container_name] if f[:container_name].present?
            parts << f[:container_path] if f[:container_path].present?
            parts << f[:file_name]

            zip.add(File.join(parts), f[:retrieval_path])
          end
        end
        target_path || temp_file
      end

    end
  end
end
