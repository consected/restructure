# frozen_string_literal: true

# ProcessHandler provides logic for running a chain of jobs after a file upload
module NfsStore
  module Process
    class ProcessHandler
      DefaultJobList = %i[mount_archive index_files dicom_metadata].freeze
      attr_accessor :container_file, :parent_item, :container

      def initialize(container_file)
        self.container_file = container_file
        self.container = container_file.container
        # Save the parent_item activity log so we can use it to pick up additional configurations
        self.parent_item = container&.find_creator_parent_item
      end

      def pipeline_config
        parent_item&.extra_log_type_config&.nfs_store && parent_item.extra_log_type_config.nfs_store[:pipeline]
      end

      def pipeline_job_list
        pipeline_config.map { |p| p.first.first.to_sym }
      end

      # List of valid processing jobs.
      # Can be extended to dynamically select jobs based on container configuration
      def job_list
        return pipeline_job_list if pipeline_config

        DefaultJobList
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
      def run(name)
        return unless name

        puts "Job Running: (#{name}) of (#{job_list})"
        Rails.logger.info "Job Running: (#{name}) of (#{job_list})"

        classname = "#{name}_job".camelize
        c = self.class.parents.first.const_get classname

        c.perform_later container_file, parent_item

        container_file.current_user = container_file.user
        container_file.last_process_name_run = name
        container_file.save!
      end

      # Run the next job in the job_list
      # @param current_name [String] name of the current job
      def run_next_job_after(current_name)
        next_name = next_job_after current_name

        unless next_name
          container_file.current_user = container_file.user
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
      def next_job_after(name)
        i = job_list.index(name)
        return unless i

        job_list[i + 1]
      end

      #
      # Get the configuration for the named pipeline job
      # @param [NfsStore::Manage::ArchivedFile|NfsStore::Manage::StoredFile|NfsStore::Manage::Container|ActivityLog] container_file
      #   Any one of these items allowing us to identify the activity log instance
      # @param [String | Symbol] name representing the job config to retrieve
      # @return [Hash] configuration
      def self.pipeline_job_config(item, name)
        if item.respond_to? :container
          container = item.container
        elsif item.is_a? NfsStore::Manage::Container
          container = item
        end

        if container
          activity_log = container.parent_item
        elsif item.is_a? ActivityLog
          activity_log = item
        else
          raise FsException::Action, "pipeline_job_config was provided an item that could not be used to resolve an activity log: #{item}"
        end

        pipeline = activity_log.extra_log_type_config.nfs_store[:pipeline]

        NfsStore::Config::ExtraOptions.pipeline_item_config(pipeline, name)
      end
    end
  end
end
