# frozen_string_literal: true

module NfsStore
  module Scripted
    #
    # Handle the running of scripts as jobs
    #
    class ScriptHandler
      # Default timeout for commands if not otherwise specified
      MaxRunTime = 10
      # Literal to be replaced in config[:args] array, with the retrieval_path of the current file
      ArgContainerFilePath = 'container_file_path'
      # Configurations may only contain these keys. Others will be ignored
      ValidConfigMethods = %i[script_filename environment args fail_silently timeout on_success].freeze
      # Methods that may be performed after a successful command has completed
      OnSuccessMethods = %i[store_files].freeze

      # @!attribute config
      #   @return [Hash] - configuration Hash with keys specified in `ValidConfigMethods`.
      #   @see {#initialize} for full information
      # @!attribute container_file
      #   @return [NfsStore::Manage::ContainerFile] - current container file being processed
      # @!attribute success
      #   @return [Boolean] - command successfully run
      # @!attribute result
      #   @return [Array{String} | nil] - array of strings, one for each line containing a
      #     value in the data returned from the command
      attr_accessor :config, :container_file, :result, :success
      attr_accessor(*ValidConfigMethods)

      #
      # The directory that all scripts must be in to run
      # @return [String]
      def self.scripted_job_directory
        if Rails.env.test?
          Rails.root.join('spec/fixtures/scripted_job_scripts')
        else
          Settings::ScriptedJobDirectory.freeze
        end
      end

      # @param [NfsStore::Manage::ContainerFile] container_file represents a stored or archived file
      # @param [Hash] config
      # @return [Boolean] result success
      def self.run_script(container_file, config)
        sh = new(config)
        sh.run_script(container_file)
      end

      # Use the pipeline configuration to run a script as a job
      # relying on the extra log type configuration
      # @param [NfsStore::Manage::ContainerFile] - container file to process against
      # @return [Boolean] result success
      def run_script(container_file)
        # Ensure the permissions allow the script to run successfully
        container_file.current_user ||= container_file.user if container_file
        self.container_file = container_file

        cmd = []
        cmd << environment if environment
        cmd << script_path
        cmd += arg_substitutions if args

        self.success = do_cmd(cmd)

        unless success
          Rails.logger.warn "run_script failed: #{cmd}"
          raise FphsException, 'run_script failed' unless fail_silently
        end

        handle_results

        success
      end

      #
      # Run the executable, checking for a timeout (from `#timeout`).
      # Returns success or failure based on the exit code of the script.
      # Generates the {#result} array (of strings), removing nils and setting it to nil
      # if the array is empty
      # @param [Array] cmd - defined as [(environment hash), script path, (arg1, arg2, ...)]
      # @return [Boolean] success
      def do_cmd(cmd)
        res = nil
        self.result = nil
        Rails.logger.info "Running scripted job command: #{cmd}"
        IO.popen(cmd) do |stdinout|
          Timeout.timeout(timeout) do
            res = stdinout.read
          end
        rescue Timeout::Error
          ::Process.kill 9, stdinout.pid
          Rails.logger.warn "Process popen timed out (#{timeout} sec): #{cmd}"
        end
        rescode = $?
        exit_res = !!rescode.success?

        if exit_res && res
          # Split the results, remove nils and set to nil if the result is empty
          res = res.split("\n").compact
          res = nil if res.empty?
          self.result = res
        else
          Rails.logger.warn "Failed scripted job with error code: #{rescode}"
        end

        exit_res
      end

      #
      # After a successful script, handle results according to the
      # :on_success configuration
      # This iterates through the {OnSuccessMethods} and calls the
      # method {OnSuccessMethodName.perform}
      # @return [Boolean] success
      def handle_results
        return unless success && on_success.present?

        res = true

        OnSuccessMethods.each do |m|
          m_config = on_success[m]
          next unless m_config

          performer = "NfsStore::Scripted::OnSuccess#{m.to_s.camelize}".constantize
          res &&= performer.perform self, container_file, m_config
        end

        res
      end

      #
      # Absolute path to script file
      # @return [String]
      def script_path
        @script_path ||= File.join(self.class.scripted_job_directory, script_filename)
      end

      # Handle {{substitutions}} in each argument.
      # Replace the container_file_path literal with the actual full path to the file
      # in the arguments, if specifed
      def arg_substitutions
        args&.map do |a|
          if a == ArgContainerFilePath
            rp = container_file.retrieval_path
            raise FphsException, "#{ArgContainerFilePath} substitution returns nil retrieval path" unless rp

            rp
          elsif a.include? '{{'
            Formatter::Substitution.substitute(a, data: container_file) || ''
          else
            a
          end
        end
      end

      protected

      #
      # Initialize the script handler with the supplied config,
      # which is typically defined in an activity configuration
      # Only run scripts from the defined directory ScriptedJobDirectory
      # Script filenames must not contain / characters, which will raise an exception
      # Arguments are provided as an array of strings.
      # Environment variables (additional to the delayed_job / Rails environment) are simple
      # VAR: value pairs
      # @param [Hash] config
      # @option config [String] :script_filename - filename of script to run
      # @option config [Array{String} | nil] :args - (optional) arguments
      #     allows {{substitutions}} or the literal 'container_file_path' to use
      #     the full path to the current file
      # @option config [Hash | nil] :environment - (optional) environment variables (allows {{substitutions}})
      # @option config [Boolean | nil] :fail_silently - (optional) truthy value to ignore failure exit codes & timeouts
      # @option config [Integer | nil] :timeout - (optional) fail after number of seconds if has not
      #     returned (default is 10)
      # @option config [Hash | nil] :on_success - (optional) list of functions to perform
      #     (in order) after a successful run, based on the results. Format as:
      #         { method_name1 => { options: ... },  method_name2=> ... }
      def initialize(config)
        self.config = config

        ValidConfigMethods.each { |m| instance_variable_set("@#{m}", config[m]) }

        if !script_filename.is_a?(String) || script_filename.include?('/')
          raise FphsException, 'ScriptHandler invalid script_filename'
        end

        raise FphsException, 'ScriptHandler script_filename not found' unless File.exist? script_path

        self.timeout ||= MaxRunTime
      end
    end
  end
end
