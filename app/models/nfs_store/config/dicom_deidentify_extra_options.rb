# frozen_string_literal: true

module NfsStore
  module Config
    class DicomDeidentifyExtraOptions
      def self.config_def(if_extras: {})
        {
          dicom_deidentify: {
            file_filters: 'Array of (or single String) regex filters defining the files to apply this to',
            recursive: 'true|false - apply this recursively through the metadata tree',
            set_tags: {
              tag_id: 'value to apply',
              tag_id_2: {
                value: 'value to apply',
                enum: 'true|false'
              }
            },
            delete_tags: ['tag_name']
          }
        }
      end

      def initialize(config, item)
        super
        @model_defs = config
      end

      # Clean the configuration definition and give it a consistent structure
      def self.clean_def(config)
        return unless config

        config.each do |pi|
          pi[:file_filters] = [pi[:file_filters]] if pi[:file_filters].is_a? String
          pi[:set_tags] ||= {}
          pi[:delete_tags] ||= []
        end
      end
    end
  end
end
