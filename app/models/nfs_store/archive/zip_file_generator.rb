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
      # @return [TempFile] zip file object
      def self.zip_retrieved_items retrieved_items
        temp_file = Tempfile.new([ZipTempFilePrefix, '.zip'], tmpdir)
        #This is the tricky part
        #Initialize the temp file as a zip file
        Zip::OutputStream.open(temp_file) { |zos| }


        multi_containers = retrieved_items.map{|r| r[:container_id]}.uniq.length > 1

        #Add files to the zip file as usual
        Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
          retrieved_items.each do |f|
            parts = []
            parts << "container-#{f[:container_id]}-#{f[:parent_name]}" if multi_containers
            parts << f[:container_path] if f[:container_path].present?
            parts << f[:file_name]

            zip.add(File.join(parts), f[:retrieval_path])
          end
        end
        return temp_file

      end

    end
  end
end
