# frozen_string_literal: true

module NfsStore
  module Process
    class DicomMetadataJob < NfsStoreJob
      # retry_on FphsException
      queue_as :nfs_store_process

      flow_control :dicom_metadata,
                   skip_if: lambda { |container_file|
                              container_file.is_a?(NfsStore::Manage::ContainerFile) && !(
                                container_file.content_type == 'application/dicom' ||
                                container_file.is_archive?
                              )
                            }

      def perform(container_files, activity_log = nil, _options = {})
        log "Extracting DICOM metadata"

        container_files = [container_files] if container_files.is_a? NfsStore::Manage::ContainerFile

        container_files.each do |container_file|
          container_file.container.parent_item ||= activity_log

          if container_file.is_archive?
            container_file.current_user = container_file.user
            afs = container_file.archived_files.all
            afs.each do |af|
              NfsStore::Dicom::MetadataHandler.extract_metadata_from af
            end
          else
            NfsStore::Dicom::MetadataHandler.extract_metadata_from container_file
          end
        end
      end
    end
  end
end
