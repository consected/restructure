# ProcessHandler provides logic for running a chain of jobs after a file upload
module NfsStore
  module Process
    class ProcessHandler

      attr_accessor :container_file

      def initialize container_file
        self.container_file = container_file
      end

      # List of valid processing jobs.
      # Can be extended to dynamically select jobs based on container configuration
      # in the future
      def job_list
        %w(mount_archive dicom_metadata)
      end

      # File path for flag to indicate file is being processed
      # @return [String] file path
      def processing_flag_file_path
        "#{container_file.retrieval_path}.__processing__"
      end

      # Start running the processors by starting with the first
      # @todo extend to allow configuration of what runs, based on the container configuration
      # @return
      def run_all
        FileUtils.touch processing_flag_file_path
        run job_list.first
      end

      # Run a specific job, based on its name
      # @param name [String] a job type that appears in job_list
      def run name
        return unless name
        classname = "#{name}_job".camelize
        c = self.class.parents.first.const_get classname
        c.perform_later self.container_file

        container_file.last_process_name_run = name
        container_file.save!

      end



      # Run the next job in the job_list
      # @param current_name [String] name of the current job
      def run_next_job_after current_name

        next_name = next_job_after current_name

        unless next_name
          container_file.last_process_name_run = '_all_done_'
          container_file.save!
          FileUtils.rm_f processing_flag_file_path
          return
        end

        run next_name
      end

      # Find the name of the next job in the job_list
      # @param name [String] name of the previous job
      # @return [String] name of the next job in the job_list
      def next_job_after name
        i = job_list.index(name)
        return unless i
        job_list[i+1]
      end

    end
  end
end
