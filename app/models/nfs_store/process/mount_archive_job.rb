module NfsStore
  module Process
    class MountArchiveJob < ApplicationJob

      # retry_on FphsException
      queue_as :nfs_store_process

      # Check whether the job should be enqueued or just skipped
      around_enqueue do |job, block|
        container_file = job.arguments.first
        if NfsStore::Archive::Mounter.has_archive_extension? container_file
          block.call
        else
          container_file = job.arguments.first
          ProcessHandler.new(container_file).run_next_job_after 'mount_archive'
        end
      end

      after_perform do |job|
        container_file = job.arguments.first
        ProcessHandler.new(container_file).run_next_job_after 'mount_archive'
      end

      def perform(container_file)
        puts "Mounting archive file #{container_file}"
        container_file.current_user = container_file.user
        NfsStore::Archive::Mounter.mount container_file
      end
    end
  end
end
