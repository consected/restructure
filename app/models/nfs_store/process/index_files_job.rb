# frozen_string_literal: true

module NfsStore
  module Process
    class IndexFilesJob < NfsStoreJob
      # retry_on FphsException
      queue_as :nfs_store_process

      flow_control :index_files,
                   skip_if: lambda { |container_file|
                              container_file.is_a?(NfsStore::Manage::ContainerFile) &&
                                !container_file.is_archive?
                            }

      def perform(container_files, in_app_type_id, activity_log = nil, _options = {})
        log 'Indexing files'

        container_files = [container_files] if container_files.is_a? NfsStore::Manage::ContainerFile

        container_files.each do |container_file|
          container_file.container.parent_item ||= activity_log
          setup_container_file_current_user(container_file, in_app_type_id)
          NfsStore::Archive::Mounter.index container_file
        end
      end
    end
  end
end
