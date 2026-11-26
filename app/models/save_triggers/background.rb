# frozen_string_literal: true

#
# Save trigger that runs other save triggers in a background job.
# This is useful for long-running operations that shouldn't block the main request.
#
# Example configurations:
#   background:
#     - create_reference:
#         model_name:
#           in: master
#   background:
#     with:
#       loop_value: "{{{save_trigger_results.loop_result_value}}}"
#     do:
#       - log:
#           message: "Processing {{background_context.loop_value}}"
#
class SaveTriggers::Background < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super

    # Use the base class's normalized config, which has on_complete and on_failure removed
    @trigger_configs = self.config
  end

  def perform
    context_form = context_form?
    raise FphsException, 'background with requires a do trigger list' if with_without_do?

    context = resolve_context if context_form
    triggers = context_form ? @trigger_configs[:do] : @trigger_configs
    if context_form && !(triggers.is_a?(Array) || triggers.is_a?(Hash))
      raise FphsException, 'background do must be a trigger list'
    end

    triggers = [triggers] unless triggers.is_a?(Array)
    if triggers.any? { |trigger| trigger.is_a?(Hash) && (trigger.key?(:with) || trigger.key?(:do)) }
      raise FphsException, 'with/do are only valid inside a background trigger hash'
    end

    item_class = @item.class.name
    item_id = @item.id
    user_id = @item.current_user&.id

    Rails.logger.info "[SaveTrigger::Background] Queuing #{triggers.length} triggers for #{item_class}##{item_id}"

    job_arguments = {
      item_class:,
      item_id:,
      user_id:,
      triggers: triggers.as_json
    }
    job_arguments[:context] = context if context_form
    SaveTriggersBackgroundJob.perform_later(**job_arguments)

    result = {
      status: 'queued',
      item_class:,
      item_id:,
      trigger_count: triggers.length,
      queued_at: Time.current
    }
    result[:context_keys] = context.keys if context_form

    store_trigger_results('background', result)

    result
  end

  private

  # Whether the config uses the context form, which is a Hash with a +do+ trigger list
  # and an optional +with+ mapping of values to pass to the job.
  # @return [Boolean]
  def context_form?
    @trigger_configs.is_a?(Hash) && @trigger_configs.key?(:do)
  end

  # Whether the config has a +with+ mapping without the required +do+ trigger list.
  # @return [Boolean]
  def with_without_do?
    @trigger_configs.is_a?(Hash) && @trigger_configs.key?(:with) && !@trigger_configs.key?(:do)
  end

  # Resolves each +with+ value in the foreground, so the job receives the values as they were when the trigger ran.
  # @return [Hash{Symbol => Object}] the resolved context, or an empty Hash when +with+ is omitted
  # @raise [FphsException] if +with+ is not a Hash or the resolved context cannot be queued
  def resolve_context
    with = @trigger_configs[:with]
    return {} unless @trigger_configs.key?(:with)
    raise FphsException, 'background with must be a Hash' unless with.is_a?(Hash)

    context = with.each_with_object({}) do |(key, value), resolved|
      resolved[key] = FieldDefaults.calculate_default(@item, value, allow_nil: true)
    end
    validate_context_serialization!(context)
    context
  end

  # Checks that each value can be serialized for ActiveJob, and that the whole context fits the size limit.
  # @param context [Hash{Symbol => Object}] the resolved context values
  # @return [void]
  # @raise [FphsException] if a value cannot be serialized, or the context exceeds
  #   Settings::SaveTriggerBackgroundContextMaxBytes
  def validate_context_serialization!(context)
    context.each do |key, value|
      ActiveJob::Arguments.serialize([value])
    rescue ActiveJob::SerializationError => e
      raise FphsException, "background context key '#{key}' cannot be serialized: #{e.message}"
    end

    # Measure the context as the job will receive it, not the individual values
    serialized_json = ActiveSupport::JSON.encode(ActiveJob::Arguments.serialize([context]).first)
    max_bytes = Settings::SaveTriggerBackgroundContextMaxBytes
    return if serialized_json.bytesize <= max_bytes

    raise FphsException,
          "background context exceeds the configured size limit of #{max_bytes} bytes"
  rescue ActiveJob::SerializationError => e
    raise FphsException, "background context cannot be serialized: #{e.message}"
  end
end
