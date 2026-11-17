# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the generate_document save trigger.
    # Named-entry pattern: keys are validated inside each entry config.
    class GenerateDocument < Base
      trigger_name :generate_document
      pattern :named_entry
      allowed_keys %i[
        content_template_name content_template_text layout_template extra_substitutions
        container filename content_type path skip_existing replace
        store_as_user store_in_app_type if on_complete on_failure
      ]
      standard_hook_key_types
      key_type :string_or_hash, :content_template_name, :content_template_text, :layout_template,
               :filename, :content_type, :path
      # store_as_user/store_in_app_type accept a literal id/name, a {{substitution}}, or
      # a conditional Hash reference (e.g. {this: {field: return_value}}) - resolved via
      # FieldDefaults before being passed to the id/name lookup (see
      # SaveTriggers::GenerateDocument#resolve_user).
      key_type :string_or_integer_or_hash, :store_as_user, :store_in_app_type
      key_type :hash, :extra_substitutions, :container
      key_type :boolean, :skip_existing, :replace

      class << self
        def validate_config(config)
          return config.flat_map { |entry| validate_config(entry) } if config.is_a?(Array)
          return [] unless config.is_a?(Hash)

          warnings = super
          semantic_configs(config).each do |inner|
            next unless inner.is_a?(Hash)

            inner = inner.transform_keys(&:to_sym)
            warnings.concat(validate_app_type_ref(inner[:store_in_app_type], 'store_in_app_type'))
            warnings.concat(validate_user_ref(inner[:store_as_user], 'store_as_user'))
          end
          warnings
        end

        private

        def semantic_configs(config)
          non_lifecycle_keys = config.keys.map(&:to_sym) - %i[if on_complete on_failure]
          return [config] if non_lifecycle_keys.any? { |key| allowed_keys.include?(key) }

          config.values
        end
      end
    end
  end
end
