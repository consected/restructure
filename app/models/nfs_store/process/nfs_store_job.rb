# frozen_string_literal: true

module NfsStore
  module Process
    # Background job for handling Dicom deidentification according to
    # activity log / nfs_store configurations
    class NfsStoreJob < ApplicationJob
      #
      # Handle flow control through enqueue callbacks
      # @param [String] name is the name of the job
      # @param [Proc] skip_if a lambda that is called to decide if a job should be skipped
      #
      def self.flow_control(name, skip_if: nil)
        # Check whether the job should be enqueued or just skipped
        around_enqueue do |job, block|
          container_file = job.arguments.first
          if skip_if&.call(container_file)
            block.call
          else
            NfsStore::Process::ProcessHandler.new(container_file).run_next_job_after name
          end
        end

        after_perform do |job|
          container_file = job.arguments.first
          NfsStore::Process::ProcessHandler.new(container_file).run_next_job_after name
        end
      end
    end
  end
end
