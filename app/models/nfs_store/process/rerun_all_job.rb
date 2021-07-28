# frozen_string_literal: true

module NfsStore
  module Process
    # Background job for handling Dicom deidentification according to
    # activity log / nfs_store configurations
    class RerunAllJob < NfsStoreJob
      # retry_on FphsException
      queue_as :nfs_store_process

      flow_control :rerun_all

      # Perform the job (called in the background from ActiveJob),
      # to trigger all jobs to run again.
      # @param [NfsStore::Manage::ArchivedFile | NfsStore::Manage::StoredFile] container_file
      def perform(container_files, in_app_type_id, _activity_log = nil, _call_options = {})
        log 'Rerun all file jobs'

        container_files = [container_files] if container_files.is_a? NfsStore::Manage::ContainerFile

        container_files.each do |container_file|
          container_file.container
          setup_container_file_current_user(container_file, in_app_type_id)

          if container_file.respond_to? :last_process_name_run
            container_file.last_process_name_run = nil
            container_file.save!
          end
        end
      end
    end
  end
end
