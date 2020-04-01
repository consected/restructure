# frozen_string_literal: true

module NfsStore
  module Process
    class MountArchiveJob < NfsStoreJob
      # retry_on FphsException
      queue_as :nfs_store_process

      flow_control :mount_archive, skip_if: ->(container_file) { container_file.is_archive? }

      def perform(container_file, activity_log = nil)
        log "Mounting archive file #{container_file}"
        container_file.container.parent_item ||= activity_log
        container_file.current_user = container_file.user
        NfsStore::Archive::Mounter.mount container_file
      end
    end
  end
end
