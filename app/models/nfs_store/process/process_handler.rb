# frozen_string_literal: true

# ProcessHandler provides logic for running a chain of jobs after a file upload
module NfsStore
  module Process
    class ProcessHandler
      DefaultJobList = %i[mount_archive index_files dicom_metadata].freeze
      LastProcessAllDone = '_all_done_'
      attr_accessor :container_files, :parent_item, :container, :call_options, :use_pipeline_config

      #
      # Initialize the process handler
      # @param [NfsStore::Manage::ContainerFile] container_file
      # @param [Hash] call_options
      # @option call_options [Hash] :use_pipeline definition of pipeline to use,
      #    for example: { user_file_actions: action_id }
      # @option call_options [Array] :use_pipeline_config is the definition of a pipeline to use
      # @option call_options [Boolean] :do_not_run_job_after prevent the next job from running on 'skip' or completion
      def initialize(container_files, call_options = {})
        if container_files.is_a? Array
          container_file = container_files.first
          self.container_files = container_files
        else
          container_file = container_files
          self.container_files = [container_files]
        end

        raise FsException::Action, 'no file selected to process' unless container_file

        self.container = container_file.container
        # Save the parent_item activity log so we can use it to pick up additional configurations
        self.parent_item = container&.parent_item || container&.find_creator_parent_item
        self.call_options = call_options

        use_pipeline = call_options[:use_pipeline]
        if use_pipeline.is_a? Hash
          action_id = use_pipeline[:user_file_actions]
          self.use_pipeline_config = self.class.user_file_action_pipeline(container_file, action_id)
          unless use_pipeline_config
            raise FphsException, "Specified user file action #{action_id} did not find a definition"
          end
        else
          self.use_pipeline_config = call_options[:use_pipeline_config]
        end
      end

      def nfs_store_config
        parent_item&.extra_log_type_config&.nfs_store || {}
      end

      def pipeline_config
        use_pipeline_config || nfs_store_config[:pipeline]
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
      def processing_flag_file_path(container_file)
        "#{container_file.retrieval_path}.__processing__"
      end

      def set_processing_flags
        container_files.each do |container_file|
          FileUtils.touch processing_flag_file_path(container_file)
        end
      end

      def clear_processing_flags
        container_files.each do |container_file|
          FileUtils.rm_f processing_flag_file_path(container_file)
        end
      end

      # Start running the processors by starting with the first
      # @todo extend to allow configuration of what runs, based on the container configuration
      # @return
      def run_all
        set_processing_flags
        run job_list.first
      end

      # Run a specific job, based on its name
      # @param name [String] a job type that appears in job_list
      def run(name)
        return unless name

        puts "Job Running: (#{name}) of (#{job_list})" unless Rails.env.test?
        Rails.logger.info "Job Running: (#{name}) of (#{job_list})"

        self.container_files = [container_files] if container_files.is_a? NfsStore::Manage::ContainerFile

        self.class.job_class(name).perform_later container_files, app_type_id_for_file_user, parent_item, call_options

        set_container_file_statuses name
      end

      # Run the next job in the job_list
      # @param current_name [String] name of the current job
      def run_next_job_after(current_name)
        next_name = next_job_after current_name

        unless next_name
          set_container_file_statuses LastProcessAllDone
          clear_processing_flags
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
      # Set the status of #last_process_name_run to *name*
      # for all container files
      def set_container_file_statuses(name)
        self.class.set_container_file_statuses(name, container_files)
      end

      def self.set_container_file_statuses(name, container_files)
        container_files.each do |container_file|
          next unless container_file.respond_to? :last_process_name_run=

          container_file.last_process_name_run = name
          container_file.current_user = container_file.user
          container_file.force_save!
          container_file.save!
        end
      end

      def self.job_class(name)
        classname = "#{name}_job".camelize

        nparts = self.name.split('::')[0..-2]&.join('::') || 'Object'
        nparts.constantize.const_get classname
      end

      #
      # Get the activity log for a container or container_file
      # @param [NfsStore::Manage::Container | NfsStore::Manage::ContainerFile | ActivityLog] item <description>
      # @return [ActivityLog] activity log from a matched container parent item
      def self.activity_log_for(item)
        if item.respond_to? :container
          container = item.container
        elsif item.is_a? NfsStore::Manage::Container
          container = item
        end

        if container
          activity_log = container.parent_item || container.find_creator_parent_item
        elsif item.is_a? ActivityLog
          activity_log = item
        else
          raise FsException::Action, "item could not be used to resolve an activity log: #{item}"
        end

        activity_log
      end

      #
      # Get the configuration for the named pipeline job
      # @todo handle when there is more than one named job in a pipeline (such as dicom_deidentify)
      # @param [String | Symbol] name representing the job config to retrieve
      # @return [Hash] configuration
      def pipeline_job_config(name)
        NfsStore::Config::ExtraOptions.pipeline_item_configs(pipeline_config, name)&.first&.first&.last
      end

      #
      # Get the configuration for the user file action pipeline job
      # @param [NfsStore::Manage::ArchivedFile|NfsStore::Manage::StoredFile|NfsStore::Manage::Container|ActivityLog] container_file
      #   Any one of these items allowing us to identify the activity log instance
      # @param [String | Symbol] name representing the job config to retrieve
      # @return [Hash] configuration
      def self.user_file_action_pipeline(item, action_name)
        raise FsException::Action, 'item not set for file action pipeline request' unless item

        activity_log = activity_log_for item
        raise FsException::Action, 'activity log not found for file action pipeline request' unless activity_log

        user_file_actions = activity_log.extra_log_type_config.nfs_store[:user_file_actions]

        ufa = NfsStore::Config::UserFileActionsExtraOptions.user_file_action_item(user_file_actions, action_name)
        ufa[:pipeline] if ufa
      end

      #
      # Assume that all #container_files are related - get the first and use it to
      # lookup the current user or saved user for the file and its Admin::AppType #id
      def app_type_id_for_file_user
        cf = container_files.first
        (cf.current_user || cf.user)&.app_type_id
      end

      #
      # The current app_type_id of a user for a persisted container file may change over time. Rather than relying on
      # the value set at some arbitrary time, we use the default app_type_id for the current context.
      # @return [Integer] app_type_id
      def self.default_app_type_id
        Settings.nfs_store_default_app_type_id
      end

      # Convenience wrapper around the class method. NOTE: this instance method
      # does NOT restore the user's app_type_id after the call. Use
      # NfsStoreJob#setup_container_file_current_user (which wraps in begin/ensure)
      # whenever a restore is required. Calling this directly is safe only when
      # the caller takes responsibility for restoring the user's in-memory state.
      # @see ProcessHandler.setup_container_file_current_user
      def setup_container_file_current_user(container_file)
        self.class.setup_container_file_current_user(container_file, app_type_id_for_file_user)
      end

      #
      # Set the current_user in the supplied container_file. If the #user of the container_file
      # is no longer active, or has no nfs_store group roles, use the Batch User instead,
      # setting it to the in_app_type_id app.
      # @param [NfsStore::Manage::ContainerFile] container_file
      # @param [Integer] in_app_type_id - id of the Admin::AppType for the Batch User if needed
      def self.setup_container_file_current_user(container_file, in_app_type_id)
        user = container_file.user
        orig_user = user

        if user.disabled
          Rails.logger.warn "Job container file user (#{user.id}) is disabled, using batch user instead for app type: #{in_app_type_id}"
          user = User.use_batch_user(in_app_type_id)
          unless user_has_nfs_group_role?(user)
            raise FsException::Action,
                  "Job container file user (#{orig_user.id}) is disabled and batch user (#{User.batch_user&.email}) does not have an " \
                  "nfs_store group role in the current app: #{user.app_type_id} || #{in_app_type_id}"
          end
        else
          # Normalize the user's app_type_id in-memory first, so that the subsequent role check
          # queries roles in the correct (default) app type context. user.user_roles is scoped by
          # user.app_type_id, so nfs_store group roles registered under default_app_type_id would
          # be invisible if we checked before normalizing.
          if user.app_type_id != default_app_type_id
            Rails.logger.warn "ProcessHandler - temporarily switching user #{user.id} app_type_id from #{user.app_type_id} to #{default_app_type_id}"
            user.app_type_id = default_app_type_id
          end

          unless user_has_nfs_group_role?(user)
            Rails.logger.warn "Job container file user (#{orig_user.id}) has no nfs_store group roles, using batch user instead for app type: #{in_app_type_id}"
            user = User.use_batch_user(in_app_type_id)
            unless user_has_nfs_group_role?(user)
              raise FsException::Action,
                    "Job container file user (#{orig_user.id}) has no nfs_store group role and batch user (#{User.batch_user&.email}) " \
                    "does not have an nfs_store group role in the current app: #{user.app_type_id} || #{in_app_type_id}"
            end
          end
        end

        container_file.current_user = user
        # Clear memoized role names/group ids since the container's current_user may have changed
        container_file.container.instance_variable_set(:@current_user_role_names, nil)
        container_file.container.instance_variable_set(:@current_user_group_ids, nil)
        return user if container_file.current_role_name

        Rails.logger.info "Setting current role name for user #{user.id} in app type #{in_app_type_id}"
        _, role_name = container_file.file_path_and_role_name
        container_file.current_role_name = role_name
        user
      end

      # Check whether a user has at least one active nfs_store group role
      # @param [User] user
      # @return [Boolean]
      def self.user_has_nfs_group_role?(user)
        user.user_roles.active.pluck(:role_name).any? { |r| r.start_with? 'nfs_store group ' }
      end
      private_class_method :user_has_nfs_group_role?
    end
  end
end
