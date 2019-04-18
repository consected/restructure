module NfsStore
  module Process
    class IndexFilesJob < ApplicationJob

      # retry_on FphsException
      queue_as :nfs_store_process

      # Check whether the job should be enqueued or just skipped
      around_enqueue do |job, block|
        container_file = job.arguments.first
        if container_file.is_archive?
          block.call
        else
          container_file = job.arguments.first
          ProcessHandler.new(container_file).run_next_job_after 'index_files'
        end
      end

      after_perform do |job|
        container_file = job.arguments.first
        ProcessHandler.new(container_file).run_next_job_after 'index_files'
      end

      def perform(container_file)
        puts "Indexing files #{container_file}"
        container_file.current_user = container_file.user
        NfsStore::Archive::Mounter.index container_file
      end
    end
  end
end
