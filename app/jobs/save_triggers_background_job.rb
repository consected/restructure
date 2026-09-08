# frozen_string_literal: true

#
# Job to execute save triggers in the background.
# Used by SaveTriggers::Background to run triggers asynchronously.
#
class SaveTriggersBackgroundJob < ApplicationJob
  queue_as :default

  #
  # Execute the specified save triggers for an item
  # @param [String] item_class - the class name of the item
  # @param [Integer] item_id - the ID of the item
  # @param [Integer] user_id - the ID of the user to run as
  # @param [Array<Hash>] triggers - array of trigger configurations
  def perform(item_class:, item_id:, user_id:, triggers:)
    Rails.logger.info "[SaveTriggersBackgroundJob] Starting for #{item_class}##{item_id}"

    # Resolve the model class via the Resources::Models registry (allow-list) rather
    # than String#constantize. This prevents arbitrary class autoloading even if a
    # malicious or corrupted job payload provides an unexpected class name.
    klass = Resources::Models.find_model!(item_class)

    # Refresh this item type's cached definition from the database before running
    # triggers. `klass.definition` is a process-wide, memoized singleton
    # (`option_configs` only re-parses when explicitly forced) - a long-running
    # background worker process may have parsed and cached it before an admin last
    # updated the definition (e.g. added `_constants`), and would otherwise keep
    # using that stale, already-parsed copy forever. See issue #1406.
    # NOTE: this always reparses rather than checking timestamps first, since
    # `_constants`/`_configurations` may be sourced from a config library whose own
    # update would not bump this definition's own `updated_at` - see PR discussion.
    if klass.respond_to?(:definition) && klass.definition
      klass.definition.reload
      klass.definition.force_option_config_parse
    end

    item = klass.find(item_id)

    # Set the current user
    if user_id
      user = User.find(user_id)
      item.current_user = user
    end

    # Initialize save_trigger_results if needed
    item.save_trigger_results ||= {} if item.respond_to?(:save_trigger_results=)

    results = []

    # Execute each trigger
    triggers.each do |trigger_config|
      trigger_config = trigger_config.deep_symbolize_keys
      next unless trigger_config.is_a?(Hash)

      trigger_config.each do |trigger_name, config|
        trigger_name = trigger_name.to_sym

        # Resolve via the same allow-list validation foreground execution uses
        # (OptionConfigs::ExtraOptions.trigger_class), rather than a raw
        # SaveTriggers.const_get, so a corrupted job payload can't reach an
        # unintended constant.
        trigger_klass = OptionConfigs::ExtraOptions.trigger_class(trigger_name)
        trigger = trigger_klass.new(config, item)
        result = trigger.perform
        results << { trigger: trigger_name, result: }

        Rails.logger.info "[SaveTriggersBackgroundJob] Completed trigger: #{trigger_name}"
      end
    end

    Rails.logger.info "[SaveTriggersBackgroundJob] Completed #{results.length} triggers for #{item_class}##{item_id}"

    results
  end
end
