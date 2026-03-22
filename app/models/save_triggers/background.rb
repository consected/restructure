# frozen_string_literal: true

#
# Save trigger that runs other save triggers in a background job.
# This is useful for long-running operations that shouldn't block the main request.
#
# Example configuration:
#   save_trigger:
#     on_create:
#       background:
#         - create_reference:
#             model_name:
#               in: master
#         - notify:
#             type: email
#             ...
#         - update_this:
#             one:
#               with:
#                 status: processing
#
class SaveTriggers::Background < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super

    @trigger_configs = config
  end

  def perform
    # The config should be an array of trigger configurations
    triggers = @trigger_configs
    triggers = [triggers] unless triggers.is_a?(Array)

    # Serialize the necessary data for the background job
    item_class = @item.class.name
    item_id = @item.id
    user_id = @item.current_user&.id

    Rails.logger.info "[SaveTrigger::Background] Queuing #{triggers.length} triggers for #{item_class}##{item_id}"

    # Queue the job
    SaveTriggersBackgroundJob.perform_later(
      item_class:,
      item_id:,
      user_id:,
      triggers: triggers.as_json
    )

    result = {
      status: 'queued',
      item_class:,
      item_id:,
      trigger_count: triggers.length,
      queued_at: Time.current
    }

    store_trigger_results('background', result)

    result
  end
end
