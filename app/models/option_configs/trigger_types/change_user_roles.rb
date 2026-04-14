# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the change_user_roles save trigger.
    # Direct-config pattern: keys are directly on the trigger config hash.
    class ChangeUserRoles < Base
      trigger_name :change_user_roles
      pattern :direct_config
      allowed_keys %i[if add_role_names remove_role_names on_complete on_failure]
    end
  end
end
