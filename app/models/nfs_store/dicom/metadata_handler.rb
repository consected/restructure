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

      def self.extract_metadata_from(container_file)
        return if container_file.content_type.blank?

        container_file.current_user = container_file.user
        full_path = container_file.retrieval_path

        begin
          # Extract the metadata
          # This is not a reliable process, so catch exceptions and just store a readable error object that can be
          # used offline to recover is desired
          mh = new(file_path: full_path)
          metadata = mh.extract_metadata
          unless metadata.nil? || metadata.is_a?(Hash)
            raise NfsStore::FsExceptionHandler::FsException, "metadata #{metadata.class} is an invalid type after extraction"
          end
        rescue StandardError => e
          metadata = {
            fphs_exception: { status: 'failed', info: 'failed to extract DICOM metadata.', exception: e.to_s }
          }
        end

        container_file.file_metadata = metadata
        container_file.save!
      end

      def extract_metadata
        raise FsException::Action, 'No file path for Dicom to extract metadata from' unless file_path
        raise FsException::Action, 'File does not exist for Dicom to extract metadata from' unless File.exist? file_path

        Rails.logger.info "Retrieving file for DICOM metadata processing: #{file_path}"

        dcm = DICOM::DObject.read(file_path)
        dcm.to_hash
      end
    end
  end
end
