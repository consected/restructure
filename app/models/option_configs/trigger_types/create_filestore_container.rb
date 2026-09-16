# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the create_filestore_container save trigger.
    # Direct-config pattern: keys are directly on the trigger config hash.
    class CreateFilestoreContainer < Base
      VALID_SKIP_IF_EXISTS = %w[master user_is_creator].freeze

      trigger_name :create_filestore_container
      pattern :direct_config
      allowed_keys %i[name label create_with_role skip_if_exists if on_complete on_failure]
      standard_hook_key_types
      key_type :string_or_hash, :name, :label, :create_with_role
      key_type :string, :skip_if_exists

      class << self
        def validate_config(config)
          warnings = super
          return warnings unless config.is_a?(Hash)

          value = config.transform_keys(&:to_sym)[:skip_if_exists]
          if (value.is_a?(String) || value.is_a?(Symbol)) && !VALID_SKIP_IF_EXISTS.include?(value.to_s)
            warnings << "skip_if_exists '#{value}' must be one of: #{VALID_SKIP_IF_EXISTS.join(', ')}"
          end

          warnings
        end
      end
    end
  end
end
