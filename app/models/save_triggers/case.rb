# frozen_string_literal: true

#
# Save trigger that implements case/when/else conditional branching.
# Evaluates when conditions in order and executes the triggers associated
# with the first matching condition. If no conditions match, executes
# the else block if present.
#
# Example configuration:
#   save_trigger:
#     on_create:
#       case:
#         - when:
#             all:
#               this:
#                 field1: value 1
#           then:
#             - log:
#                 message: Matched value 1
#             - create_reference: ...
#         - when:
#             all:
#               this:
#                 field1: value 2
#           then:
#             - update_reference: ...
#             - log:
#                 message: Matched value 2
#         - else:
#             - notify: ...
#
class SaveTriggers::Case < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super

    @case_configs = config
  end

  def perform
    branches = @case_configs
    branches = [branches] unless branches.is_a?(Array)

    results = []

    branches.each do |branch|
      next unless branch.is_a?(Hash)

      if branch.key?(:when)
        # Evaluate the when condition using ConditionalActions
        ca = ConditionalActions.new(branch[:when], @item)
        next unless ca.calc_action_if

        # Condition matched — execute the then triggers
        results = execute_triggers(branch[:then])
        break
      elsif branch.key?(:else)
        # No when matched before this — execute else triggers
        results = execute_triggers(branch[:else])
        break
      end
    end

    Rails.logger.info "[SaveTrigger::Case] Completed with #{results.length} trigger results"

    # Store results for potential use by subsequent triggers
    if @item.respond_to?(:save_trigger_results) && @item.save_trigger_results
      @item.save_trigger_results['case'] = results
    end

    results
  end

  private

  #
  # Execute an array of trigger configurations
  # @param [Array<Hash>] trigger_list - list of trigger configs to execute
  # @return [Array<Hash>] results from each trigger
  def execute_triggers(trigger_list)
    return [] unless trigger_list

    trigger_list = [trigger_list] unless trigger_list.is_a?(Array)
    results = []

    trigger_list.each do |trigger_config|
      next unless trigger_config.is_a?(Hash)

      trigger_config.each do |trigger_name, config|
        trigger_name = trigger_name.to_sym
        klass = ::SaveTriggers.const_get(trigger_name.to_s.camelize)
        trigger = klass.new(config, @item)
        result = trigger.perform
        results << { trigger: trigger_name, result: }
      end
    end

    results
  end
end
