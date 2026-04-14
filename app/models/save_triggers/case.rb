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

    results = evaluate_branches(branches)

    Rails.logger.info "[SaveTrigger::Case] Completed with #{results.length} trigger results"
    store_trigger_results('case', results)

    results
  end

  private

  #
  # Iterate through branches, evaluating when conditions and executing
  # the first matching branch's then triggers, or the else triggers.
  # @param [Array<Hash>] branches - ordered list of when/then or else branches
  # @return [Array<Hash>] results from the executed triggers
  def evaluate_branches(branches)
    branches.each do |branch|
      next unless branch.is_a?(Hash)

      if branch.key?(:when)
        next unless if_evaluates(branch[:when])

        return execute_trigger_list(branch[:then])
      elsif branch.key?(:else)
        return execute_trigger_list(branch[:else])
      end
    end

    []
  end
end
