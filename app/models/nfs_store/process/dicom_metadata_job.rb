# frozen_string_literal: true

module NfsStore
  module Process
    class DicomMetadataJob < NfsStoreJob
      # retry_on FphsException
      queue_as :nfs_store_process

      flow_control :dicom_metadata, skip_if: ->(container_file) { container_file.content_type == 'application/dicom' || container_file.is_archive? }

      def perform(container_file, activity_log = nil)
        log "Extracting DICOM metadata for #{container_file}"
        container_file.container.parent_item ||= activity_log

        if container_file.is_archive?
          container_file.current_user = container_file.user
          afs = container_file.archived_files.all
          afs.each do |af|
            extract_metadata af unless af.content_type.blank?
          end
        else
          extract_metadata container_file unless container_file.content_type.blank?
        end
      end

      def extract_metadata(container_file)
        container_file.current_user = container_file.user
        full_path = container_file.retrieval_path
        return if container_file.content_type.blank?

        begin
          # Extract the metadata
          # This is not a reliable process, so catch exceptions and just store a readable error object that can be
          # used offline to recover is desired
          mh = NfsStore::Dicom::MetadataHandler.new(file_path: full_path)
          metadata = mh.extract_metadata
        rescue StandardError => e
          metadata = { fphs_exception: { status: 'failed', info: 'failed to extract DICOM metadata.', exception: e.to_s } }
        end
        container_file.file_metadata = metadata
        container_file.save!
      end
    end
  end
end
