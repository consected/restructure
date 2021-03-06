# frozen_string_literal: true

module NfsStore
  module Process
    # Superclass for jobs to inherit from
    class NfsStoreJob < ApplicationJob
      attr_writer :job

      def job
        @job || self
      end

      #
      # Get a usable, configured instance of the ProcessHandler
      # @return [ProcessHandler]
      def job_process_handler
        @job_process_handler ||= NfsStore::Process::ProcessHandler.new(job_container_file, job_call_options)
      end

      #
      # Simply return the appropriate call_options from the job
      # @return [Hash]
      def job_call_options
        job.arguments[2]
      end

      #
      # Container file from job
      # @return [NfsStore::Manage::ContainerFile]
      def job_container_file
        job.arguments.first
      end

      #
      # Do not run the next job if the call_options specifies
      # @return [Boolean]
      def do_not_run_job_after?
        job_call_options[:do_not_run_job_after]
      end

      #
      # Handle flow control through enqueue callbacks
      # @param [String] name is the name of the job
      # @param [Proc] skip_if a lambda that is called to decide if a job should be skipped
      #
      def self.flow_control(name, skip_if: nil)
        # Check whether the job should be enqueued or just skipped
        around_enqueue do |job, block|
          self.job = job
          if skip_if&.call(job_container_file)
            next if do_not_run_job_after?

            job_process_handler.run_next_job_after name
          else
            block.call
          end
        end

        after_perform do |job|
          self.job = job
          next if do_not_run_job_after?

          job_process_handler.run_next_job_after name
        end
      end
    end
  end
end
