# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Trigger-task container scoped to **config triggers** (`on_define`) only.
    #
    # `ConfigTrigger` actions (e.g. `create_defaults`, `create_configs`) are a
    # closed, fixed set that must NOT be runnable from save triggers or batch
    # triggers (which operate on user records). Sharing the global
    # `TriggerTypes` registry with `SaveTrigger` / `BatchTrigger` would expose
    # these admin-time-only actions to those runtime contexts and produce
    # noisy "unrecognized trigger action" warnings whenever a save trigger
    # mentioned an unrelated action name.
    #
    # This subclass therefore overrides {#validate_trigger_hash} to validate
    # against a closed allow-list rather than the global registry, keeping
    # `TriggerTasks` strictly for record-time triggers.
    #
    # Inner shape validation of each action's config is intentionally minimal;
    # detailed schemas live in
    # `app/models/admin/defs/config_trigger_options_defs.yaml`.
    class ConfigTriggerTasks < TriggerTasks
      # Closed allow-list of action names permitted inside `on_define`.
      ALLOWED_ACTIONS = %i[create_defaults create_configs].freeze

      private

      # Validate each trigger name in a config-trigger task hash against the
      # closed {ALLOWED_ACTIONS} list. Does not consult the global
      # `TriggerTypes` registry (which is reserved for save/batch trigger
      # actions).
      # @param hash [Hash] a single config-trigger task hash
      # @return [void]
      def validate_trigger_hash(hash)
        return unless hash.is_a?(Hash)

        hash.each_key do |trigger_name|
          next if ALLOWED_ACTIONS.include?(trigger_name.to_sym)

          add_validation_notice(
            :tasks,
            "unrecognized config_trigger action name: #{trigger_name} " \
            "(allowed: #{ALLOWED_ACTIONS.join(', ')})",
            level: :warn
          )
        end
      end
    end
  end
end
