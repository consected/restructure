# frozen_string_literal: true

module NfsStore
  module Process
    # Background job for handling Dicom deidentification according to
    # activity log / nfs_store configurations
    class DicomDeidentifyJob < ApplicationJob
      # retry_on FphsException
      queue_as :nfs_store_process

      # Check whether the job should be enqueued or just skipped
      around_enqueue do |job, block|
        container_file = job.arguments.first
        if container_file.content_type == 'application/dicom' || container_file.is_archive?
          block.call
        else
          container_file = job.arguments.first
          ProcessHandler.new(container_file).run_next_job_after 'dicom_deidentify'
        end
      end

      after_perform do |job|
        container_file = job.arguments.first
        ProcessHandler.new(container_file).run_next_job_after 'dicom_deidentify'
      end

      # Perform the job (called in the background from ActiveJob).
      # The job gets the pipeline configuration from the extra log type for
      # dicom_deidentify. It uses the filters definition to identify the files
      # to apply this to, and for each matching item it applies the deidentifcation
      # rules to the file, replacing it in the underlying storage and updating the
      # appropriate record attributes.
      # @param [NfsStore::Manage::ArchivedFile | NfsStore::Manage::StoredFile] container_file
      def perform(container_file)
        log "Overwriting DICOM metadata for #{container_file}"

        container = container_file.container

        filters = ProcessHandler.pipeline_job_config(container_file, :dicom_deidentify)[:filters]
        filtered_files = NfsStore::Filter::Filter.evaluate_container_files_as_scopes container, filters: filters

        if container_file.is_archive?
          container_file.current_user = container_file.user

          afs = filtered_files[:archived_files].where(nfs_store_stored_file_id: container_file)

          afs.each do |af|
            next if af.content_type.blank?

            deidentify_file af
          end
        else
          return if container_file.content_type.blank?

          in_filter = filtered_files[:stored_file].where(id: container_file.id).first
          return unless in_filter

          deidentify_file container_file
        end
      end

      # Use the pipeline configuration to deidentify metadata in a Dicom file, relying
      # on the extra log type configuration
      def deidentify_file(container_file)
        container_file.current_user = container_file.user
        return if container_file.content_type.blank?

        full_path = container_file.retrieval_path

        # Get the deidentify config from the activity log
        configs = ProcessHandler.pipeline_job_config(container_file, :dicom_deidentify)

        configs.each do |config|
          set_tags = config[:set_tags]
          delete_tags = config[:delete_tags]

          # Overwrite the metadata
          dh = NfsStore::Dicom::DeidentifyHandler.new(file_path: full_path)
          new_tmp_image = dh.anonymize_with(set_tags: set_tags, delete_tags: delete_tags)

          container_file.replace_file! new_tmp_image
        end
      end
    end
  end
end
