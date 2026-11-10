# frozen_string_literal: true

# Save trigger to raise/re-raise exceptions conditionally or from within lifecycle hooks.
# Supports custom error messages with substitutions, conditional raising using if,
# and re-raising original errors from within on_failure hooks.
#
# Examples:
#   save_trigger:
#     before_save:
#       exception:
#         message: 'Cannot save record with missing fields'
#         if:
#           some_field: nil
#
#   on_failure:
#     exception:
#       original_failure: true
#       message: 'Failed to process tracking item'
#
class SaveTriggers::Exception < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super

    @model_defs = self.config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |model_def|
      with_entry_lifecycle(model_def) do
        # Evaluate conditional if
        if model_def[:if]
          ca = ConditionalActions.new model_def[:if], @item
          next unless ca.calc_action_if
        end

        original_failure = model_def[:original_failure]
        message = model_def[:message]

        if original_failure
          orig_e = Thread.current[:active_save_trigger_exception]
          raise FphsException, 'exception save trigger configured with original_failure: true, but no original exception to raise (must be used within an on_failure block)' unless orig_e

          # If custom message is specified, raise FphsException wrapping both the custom message and the original error message
          if message.present?
            formatted_message = Formatter::Substitution.substitute(message, data: @item, ignore_missing: true)
            raise FphsException, "#{formatted_message}: #{orig_e.message}"
          else
            raise orig_e
          end
        else
          # Standard exception raise
          if message.present?
            formatted_message = Formatter::Substitution.substitute(message, data: @item, ignore_missing: true)
            raise FphsException, formatted_message
          else
            raise FphsException, 'An error occurred during save triggers.'
          end
        end
      end
    end
    []
  end
end
