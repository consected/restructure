# frozen_string_literal: true

module NfsStore
  module Dicom
    #
    # Handle the extraction and manipulation of DICOM metadata
    #
    class MetadataHandler
      attr_accessor :file_path

      def initialize(file_path: nil)
        self.file_path = file_path
      end

      def extract_metadata
        raise FsException::Action, 'No file path for Dicom to extract metadata from' unless file_path
        raise FsException::Action, 'File does not exist for Dicom to extract metadata from' unless File.exist? file_path

        Rails.logger.info "Retrieving file for DICOM metadata processing: #{file_path}"

        dcm = DICOM::DObject.read(file_path)
        dcm.to_hash.to_json
      end
    end
  end
end
