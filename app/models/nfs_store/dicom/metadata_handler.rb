module NfsStore
  module Dicom
    class MetadataHandler

      attr_accessor :file_path

      def initialize file_path: nil
        self.file_path = file_path
      end

      def extract_metadata

        raise FsException::Action.new "No file path for Dicom to extract metadata from" unless self.file_path
        raise FsException::Action.new "File does not exist for Dicom to extract metadata from" unless File.exists? self.file_path
        Rails.logger.info "Retrieving file for DICOM metadata processing: #{self.file_path}"

        dcm = DICOM::DObject.read(self.file_path)
        dcm.to_hash.to_json

      end

    end
  end
end
