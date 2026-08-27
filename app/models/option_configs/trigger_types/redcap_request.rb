# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the redcap_request save trigger.
    # Named-entry pattern: config is { label: { actual_keys... } }.
    class RedcapRequest < Base
      trigger_name :redcap_request
      pattern :named_entry
      not_valid_in_before_save
      allowed_keys %i[
        study project_name local_data method post_data success_if
        force_not_editable_save force_not_valid data_field data_field_format
        response_code_field allow_empty_result allow_response_codes request_options
        on_complete on_failure if
      ]
      standard_hook_key_types
      key_type :string_or_hash, :study, :project_name, :local_data, :method, :data_field, :data_field_format
      key_type :string, :response_code_field
      key_type :scalar_or_array_or_hash, :post_data
      key_type :hash, :success_if, :request_options
      key_type :array, :allow_response_codes
      key_type :boolean, :force_not_editable_save, :force_not_valid, :allow_empty_result

      def self.validate_config(config)
        warnings = super
        configurations = config.is_a?(Array) ? config : [config]
        configurations.each do |configuration|
          config_entries(configuration).each { |entry| validate_project_admin(entry, warnings) }
        end

        warnings
      end

      def self.validate_project_admin(config, warnings)
        study = config[:study]
        project_name = config[:project_name]
        return unless study.is_a?(String) && project_name.is_a?(String)
        return if dynamic_value?(study) || dynamic_value?(project_name)
        return if Redcap::ProjectAdmin.active.find_by(study:, name: project_name)

        warnings << 'study / project_name does not identify an active REDCap project'
      end

      def self.config_entries(configuration)
        return [] unless configuration.is_a?(Hash)
        return [configuration] if configuration.keys.map(&:to_sym).intersect?(allowed_keys)

        configuration.values.grep(Hash)
      end

      def self.dynamic_value?(value)
        value.include?('{{')
      end
    end
  end
end
