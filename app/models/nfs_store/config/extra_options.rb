# frozen_string_literal: true

module NfsStore
  module Config
    # Options specific to the nfs_store entry in an extra log type config
    class ExtraOptions
      def self.config_def(if_extras: {})
        pipeline = []
        pipeline << { mount_archive: {} }
        pipeline << { index_files: {} }
        pipeline << DicomDeidentifyExtraOptions.config_def
        pipeline << { dicom_metadata: {} }

        {
          pipeline: pipeline
        }
      end

      def initialize(config, item)
        super
        @model_defs = config
      end

      # Get the configuration for a specific pipeline item
      # @param [Hash] config is the configuration from { nfs_store: { pipeline: config } }
      # @param [String | Symbol] item_name the key from the pipeline config identifying the config
      # @return [Hash] configuration result
      def self.pipeline_item_config(config, item_name)
        config = config[:pipeline] if config.is_a?(Hash) && config[:pipeline]
        matches = config.select { |k| k.first.first == item_name.to_sym }.first

        # Return the value from the contained Hash
        matches&.first&.last
      end

      # Clean the configuration definition and give it a consistent structure
      def self.clean_def(config)
        DicomDeidentifyExtraOptions.clean_def(pipeline_item_config(config, :dicom_deidentify))
      end
    end
  end
end
