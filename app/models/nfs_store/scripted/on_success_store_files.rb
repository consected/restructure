# frozen_string_literal: true

module NfsStore
  module Scripted
    #
    # After running a scripted job successfully
    # store the files listed in the results
    class OnSuccessStoreFiles
      #
      # Configurations may only contain these keys. Others will be ignored
      ValidConfigMethods = %i[to_same_path_as_source to_path].freeze

      #
      # Configuration for the function.
      # A hash configuration, or true to perform with no specific config
      # Other types will cause the method to be ignored.
      # A hash config should only contain keys represented in {ValidConfigMethods}
      # @!attribute config
      #   @return [Hash | Boolean]
      #     to_same_path_as_source - true will get the path from the current container file and
      #           use it as the new stored file path
      #     to_path [String] - the path for the new stored file path
      attr_accessor :config
      attr_accessor(*ValidConfigMethods)

      # Original container file processed
      attr_accessor :container_file

      # Array of results
      # @see {ScriptHandler#result}
      attr_accessor :result

      # The ScriptHandler processing the container file
      attr_accessor :script_handler

      #
      # Perform the requested function on request
      # @param [NfsStore::Manage::ContainerFile] - the current container file
      # @param [ScriptHandler] script_handler
      #    @see {#config}
      # @param [Hash | Boolean] config
      #    @see {#config}
      # @return [Boolean | nil] result success
      def self.perform(script_handler, container_file, config)
        performer = new(script_handler, config)

        performer.perform(container_file)
      end

      #
      # Run the on success action using the initialized config
      # @param [NfsStore::Manage::ContainerFile] container_file
      # @return [Boolean | nil] success result
      def perform(container_file)
        self.container_file = container_file
        if to_same_path_as_source
          store_to_same_path_as_source
        elsif to_path
          store_to_path
        end
      end

      #
      # Store the result files to the same directory as the original container file
      # in the {NfsStore::Manage::Container}
      # @return [Boolean] success
      def store_to_same_path_as_source
        path = container_file.path
        res = true
        raise FsException::Action, 'no results returned to store' unless result

        result.each do |new_tmp_path|
          pn = Pathname.new(new_tmp_path)
          tmp_filename = pn.basename

          attrs = {
            path: path,
            file_name: tmp_filename
          }
          res &&= NfsStore::Manage::StoredFile.store_new_file(new_tmp_path, container, attrs)
        end

        res
      end

      #
      # Store the result files to the specified path in {#to_path}
      # @return [Boolean] success
      def store_to_path
        res = true
        raise FsException::Action, 'no results returned to store' unless result

        result.each do |new_tmp_path|
          attrs = {
            path: to_path,
            file_name: tmp_filename
          }
          res &&= NfsStore::Manage::StoredFile.store_new_file(new_tmp_path, container, attrs)
        end

        res
      end

      # Shortcut to the container file's container
      # @return [NfsStore::Manage::ContainerFile]
      def container
        container_file.container
      end

      def initialize(script_handler, config)
        self.script_handler = script_handler
        self.result = script_handler.result
        self.config = config

        ValidConfigMethods.each { |m| instance_variable_set("@#{m}", config[m]) }
      end
    end
  end
end
