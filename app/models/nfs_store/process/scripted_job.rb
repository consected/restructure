# frozen_string_literal: true

module NfsStore
  module Process
    # Background job for handling Dicom deidentification according to
    # activity log / nfs_store configurations
    class ScriptedJob < NfsStoreJob
      # retry_on FphsException
      queue_as :nfs_store_process

      flow_control :dicom_deidentify,
                   skip_if: lambda { |container_file|
                              container_file.is_a?(NfsStore::Manage::ContainerFile) && !(
                                container_file.content_type == 'application/dicom' ||
                                container_file.is_archive?
                              )
                            }

      # Perform the job (called in the background from ActiveJob).
      # The job gets the pipeline configuration from the extra log type for
      # 'scripted'. It uses the filters definition to identify the files
      # to apply this to, and for each matching item it applies the deidentifcation
      # rules to the file, replacing it in the underlying storage and updating the
      # appropriate record attributes.
      # @param [NfsStore::Manage::ArchivedFile | NfsStore::Manage::StoredFile] container_file
      def perform(container_files, in_app_type_id, activity_log = nil, call_options = {})
        log 'Running Scripted Job'

        container_files = [container_files] if container_files.is_a? NfsStore::Manage::ContainerFile

        container_files.each do |container_file|
          container = container_file.container
          container.parent_item ||= activity_log

          configs = NfsStore::Process::ProcessHandler.new(container_file, call_options).pipeline_job_config(:scripted)

          unless configs
            log 'Pipeline job config for scripted is nil. Trying next'
            next
          end

          c_user = setup_container_file_current_user(container_file, in_app_type_id)

          # Run through each config
          configs.each do |config|
            # Get scopes that can filter files to be deidentified
            filters = config[:file_filters]
            filtered_files = NfsStore::Filter::Filter.evaluate_container_files_as_scopes container, filters: filters

            if container_file.is_a? NfsStore::Manage::ArchivedFile
              # For an archive, get the list of files based on the archived files filter
              archived_files = filtered_files[:archived_files].where(id: container_file.id)

              # Each file is deidentified in turn
              archived_files.each do |archived_file|
                next if archived_file.content_type.blank?

                archived_file.current_user = c_user
                NfsStore::Scripted::ScriptedHandler.run_script archived_file, config
              end

            else
              # For a single stored file, filter appropriately
              next if container_file.content_type.blank?

              in_filter = filtered_files[:stored_files].where(id: container_file.id).first
              next unless in_filter

              NfsStore::Scripted::ScriptHandler.run_script container_file, config
            end
          end
        end
      end
    end
  end
end
