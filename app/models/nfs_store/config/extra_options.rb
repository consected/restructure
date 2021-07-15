# frozen_string_literal: true

module NfsStore
  module Config
    # Options specific to the nfs_store entry in an extra log type config
    class ExtraOptions
      def self.pipeline_config
        pipeline_config = []
        pipeline_config << { mount_archive: {} }
        pipeline_config << { index_files: {} }
        pipeline_config << DicomDeidentifyExtraOptions.config_def
        pipeline_config << { dicom_metadata: {} }
      end

      def self.config_def(if_extras: {})
        # {
        #   pipeline: pipeline_config,
        # user_file_actions: UserFileActionsExtraOptions.config_def
        # }
      end

      def initialize(config, item)
        super
        @model_defs = config
      end

      # Get the configurations matching an named pipeline item
      # @param [Hash] config is the configuration from { nfs_store: { pipeline: config } }
      # @param [String | Symbol] item_name the key from the pipeline config identifying the config
      # @return [Array(Hash)] configuration results as an array of hashes
      def self.pipeline_item_configs(config, item_name)
        if config.is_a?(Hash) && config[:pipeline]
          config = config[:pipeline]
        elsif config.is_a? Array
          # OK
        else
          return
        end
        config.select { |k| k.first.first == item_name.to_sym }
      end

      # Clean the configuration definition and give it a consistent structure
      def self.clean_def(config)
        pics = pipeline_item_configs(config, :dicom_deidentify)
        pics&.each do |pic|
          pic = pic.first&.last
          DicomDeidentifyExtraOptions.clean_def(pic)
        end
        UserFileActionsExtraOptions.clean_def(config[:user_file_actions])
      end
    end
  end
end
