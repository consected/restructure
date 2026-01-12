# frozen_string_literal: true

#
# Save trigger that wraps other save triggers in a database transaction.
# If any trigger raises an exception, the entire transaction is rolled back.
#
# Example configuration:
#   save_trigger:
#     on_create:
#       transaction:
#         - create_master:
#             with:
#               field_name: value
#         - create_reference:
#             model_name:
#               in: master
#         - update_this:
#             one:
#               with:
#                 status: completed
#
class SaveTriggers::Transaction < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super

    @trigger_configs = config
  end

  def perform
    # The config should be an array of trigger configurations
    triggers = @trigger_configs
    triggers = [triggers] unless triggers.is_a?(Array)

    results = []

    @item.transaction do
      triggers.each do |trigger_config|
        next unless trigger_config.is_a?(Hash)

        trigger_config.each do |trigger_name, config|
          trigger_name = trigger_name.to_sym
          # Skip non-trigger keys like 'if'
          next if trigger_name == :if

          # Get the trigger class and execute it
          klass = ::SaveTriggers.const_get(trigger_name.to_s.camelize)
          trigger = klass.new(config, @item)
          result = trigger.perform
          results << { trigger: trigger_name, result: }
        end
      end
    end

    Rails.logger.info "[SaveTrigger::Transaction] Completed #{results.length} triggers successfully"

    # Store results for potential use by subsequent triggers
    if @item.respond_to?(:save_trigger_results) && @item.save_trigger_results
      @item.save_trigger_results['transaction'] = results
    end

    results
  rescue StandardError => e
    Rails.logger.error "[SaveTrigger::Transaction] Rolled back due to error: #{e.message}"
    raise
  end
end
