# frozen_string_literal: true

module NfsStore
  module Process
    class IndexFilesJob < NfsStoreJob
      # retry_on FphsException
      queue_as :nfs_store_process

      flow_control :index_files, skip_if: ->(container_file) { container_file.is_archive? }

      def perform(container_file, activity_log = nil)
        log "Indexing files #{container_file}"
        container_file.container.parent_item ||= activity_log
        container_file.current_user = container_file.user
        NfsStore::Archive::Mounter.index container_file
      end
    end
  end
end
