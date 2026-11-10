# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the change_user_roles save trigger.
    # Direct-config pattern: keys are directly on the trigger config hash.
    class ChangeUserRoles < Base
      trigger_name :change_user_roles
      pattern :direct_config
      allowed_keys %i[if add_role_names remove_role_names on_complete on_failure]
      standard_hook_key_types
      # Each add_role_names/remove_role_names entry may be a literal role name string,
      # or a Hash of { app_type:, role_name:, for_user: }. app_type/role_name/for_user
      # each accept a literal id/name/string, a {{substitution}}, or a conditional Hash
      # reference - all resolved via FieldDefaults before use (see
      # SaveTriggers::ChangeUserRoles#handle_role_def).
      key_type :scalar_or_array_or_hash, :add_role_names, :remove_role_names,
               allowed_keys: %i[app_type role_name for_user],
               key_types: {
                 app_type: :string_or_integer_or_hash,
                 role_name: :string_or_hash,
                 for_user: :string_or_integer_or_hash
               }

      class << self
        def validate_config(config)
          return config.flat_map { |entry| validate_config(entry) } if config.is_a?(Array)
          return [] unless config.is_a?(Hash)

          warnings = super
          hash = config.transform_keys(&:to_sym)
          %i[add_role_names remove_role_names].each do |key|
            entries = hash[key]
            next unless entries

            entries = [entries] unless entries.is_a?(Array)
            entries.each do |entry|
              next unless entry.is_a?(Hash)

              entry = entry.transform_keys(&:to_sym)
              warnings.concat(validate_app_type_ref(entry[:app_type], 'app_type'))
              warnings.concat(validate_user_ref(entry[:for_user], 'for_user'))
            end
          end
          warnings
        end
      end
    end
  end
end
