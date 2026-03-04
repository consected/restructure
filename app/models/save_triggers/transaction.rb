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
    triggers = @trigger_configs
    triggers = [triggers] unless triggers.is_a?(Array)

    results = []

    @item.transaction do
      results = execute_trigger_list(triggers, skip_keys: [:if])
    end

    Rails.logger.info "[SaveTrigger::Transaction] Completed #{results.length} triggers successfully"
    store_trigger_results('transaction', results)

    results
  rescue StandardError => e
    Rails.logger.error "[SaveTrigger::Transaction] Rolled back due to error: #{e.message}"
    raise
  end
end
