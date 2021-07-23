# frozen_string_literal: true

module NfsStore
  module Process
    class MountArchiveJob < NfsStoreJob
      # retry_on FphsException
      queue_as :nfs_store_process

      flow_control :mount_archive,
                   skip_if: lambda { |container_file|
                              container_file.is_a?(NfsStore::Manage::ContainerFile) &&
                                !container_file.is_archive?
                            }

      def perform(container_files, in_app_type_id, activity_log = nil, _options = {})
        
        container_files = [container_files] if container_files.is_a? NfsStore::Manage::ContainerFile
        log "Mounting archive file #{container_files&.first&.id}"

        container_files.each do |container_file|
          container_file.container.parent_item ||= activity_log
          setup_container_file_current_user(container_file, in_app_type_id)
          res = NfsStore::Archive::Mounter.mount container_file
          unless res
            prevent_next_job!
            break
          end
          puts "Succesfful mount: #{res}"
        end
      end
    end
  end
end
