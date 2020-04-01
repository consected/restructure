# frozen_string_literal: true

module NfsStore
  module Process
    # Background job for handling Dicom deidentification according to
    # activity log / nfs_store configurations
    class DicomDeidentifyJob < NfsStoreJob
      # retry_on FphsException
      queue_as :nfs_store_process

      flow_control :dicom_deidentify, skip_if: ->(container_file) { container_file.content_type == 'application/dicom' || container_file.is_archive? }

      # Perform the job (called in the background from ActiveJob).
      # The job gets the pipeline configuration from the extra log type for
      # dicom_deidentify. It uses the filters definition to identify the files
      # to apply this to, and for each matching item it applies the deidentifcation
      # rules to the file, replacing it in the underlying storage and updating the
      # appropriate record attributes.
      # @param [NfsStore::Manage::ArchivedFile | NfsStore::Manage::StoredFile] container_file
      def perform(container_file, activity_log = nil)
        log "Overwriting DICOM metadata for #{container_file}"

        container = container_file.container
        container.parent_item ||= activity_log

        configs = NfsStore::Process::ProcessHandler.pipeline_job_config(container_file, :dicom_deidentify)

        # Run through each config
        configs.each do |config|
          # Get scopes that can filter files to be deidentified
          filters = config[:file_filters]
          filtered_files = NfsStore::Filter::Filter.evaluate_container_files_as_scopes container, filters: filters

          if container_file.is_archive?
            # For an archive, get the list of files based on the archived files filter
            container_file.current_user = container_file.user
            archived_files = filtered_files[:archived_files].where(nfs_store_stored_file_id: container_file)

            # Each file is deidentified in turn
            archived_files.each do |archived_file|
              next if af.content_type.blank?

              deidentify_file archived_file, config
            end

          else
            # For a single stored file, filter appropriately
            next if container_file.content_type.blank?

            in_filter = filtered_files[:stored_files].where(id: container_file.id).first
            next unless in_filter

            NfsStore::Dicom::DeidentifyHandler.deidentify_file container_file, config
          end
        end
      end
    end
  end
end
