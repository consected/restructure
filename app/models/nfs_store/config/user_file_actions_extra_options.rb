# frozen_string_literal: true

module NfsStore
  module Config
    class UserFileActionsExtraOptions
      def self.config_def(if_extras: {})
        [
          {
            name: 'name to present to user',
            id: '(optional) underscored identifier for the action',
            pipeline: [
              { _job_name: {} }
            ]
          }
        ]
      end

      def initialize(config, item)
        super
        @model_defs = config
      end

      # Clean the configuration definition and give it a consistent structure
      def self.clean_def(configs)
        return unless configs

        configs.each do |config|
          config[:id] ||= config[:name].id_underscore if config[:name]

          # Clean each of the pipeline definitions
          pics = ExtraOptions.pipeline_item_configs(config, :dicom_deidentify)
          pics&.each do |pic|
            pic = pic.first&.last
            DicomDeidentifyExtraOptions.clean_def(pic)
          end
        end
      end

      # Get the configuration for a specific user file action
      # @param [Hash] config is the configuration from { nfs_store: { user_file_actions: config } }
      # @param [String | Symbol] action_name the id of the user file actions definition
      # @return [Hash] configuration result
      def self.user_file_action_item(config, action_id)
        config = config[:user_file_actions] if config.is_a?(Hash) && config[:user_file_actions]
        config.select { |k| k[:id] == action_id.to_s }.first
      end

      # Get the configuration for a specific pipeline item in a user file action
      # @param [Hash] config is the configuration from { nfs_store: { user_file_actions: config } }
      # @param [String | Symbol] action_id the id of the user file actions definition
      # @param [String | Symbol] item_name the key from the pipeline config identifying the config
      # @return [Hash] configuration result
      def self.user_file_action_pipeline_item_config(config, action_id, item_name)
        action_match = user_file_action_item(config, action_id)
        matches = action_match.select { |k| k.first.first == item_name.to_sym }.first

        # Return the value from the contained Hash
        matches&.first&.last
      end
    end
  end
end
