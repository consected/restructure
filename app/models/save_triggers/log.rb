# frozen_string_literal: true

#
# Save trigger to add log entries for debugging save or batch triggers.
# Provides configurable severity levels and message formatting with substitutions.
#
# Example configuration:
#   save_trigger:
#     on_create:
#       log:
#         message: 'Processing record {{id}} for master {{master_id}}'
#         severity: info
#
class SaveTriggers::Log < SaveTriggers::SaveTriggersBase
  ValidSeverities = %w[debug info warn error].freeze

  def initialize(config, item)
    super

    @model_defs = self.config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    results = []
    @model_defs.each do |model_def|
      # Handle both simple format { message: 'x', severity: 'y' }
      # and named format { log_1: { message: 'x', severity: 'y' } }
      config = extract_config(model_def)
      with_entry_lifecycle(config) do
        # Evaluate conditional if
        if config[:if]
          ca = ConditionalActions.new config[:if], @item
          next unless ca.calc_action_if
        end

        message = config[:message]
        severity = (config[:severity] || 'info').to_s.downcase

        raise FphsException, 'log save trigger requires message to be specified' if message.blank?

        unless severity.in?(ValidSeverities)
          raise FphsException,
                "log save trigger severity must be one of #{ValidSeverities.join(', ')}, got: #{severity}"
        end

        # Perform substitutions in the message
        formatted_message = Formatter::Substitution.substitute(message, data: @item, ignore_missing: true)

        # Add context prefix for easier identification
        log_prefix = "[SaveTrigger::Log] [#{@item.class.name}##{@item.id}]"
        full_message = "#{log_prefix} #{formatted_message}"

        # Log at the appropriate severity level
        case severity
        when 'debug'
          Rails.logger.debug full_message
        when 'info'
          Rails.logger.info full_message
        when 'warn'
          Rails.logger.warn full_message
        when 'error'
          Rails.logger.error full_message
        end

        results << { message: formatted_message, severity:, logged_at: Time.current }
      end
    end

    # Store results for potential use by subsequent triggers
    if @item.respond_to?(:save_trigger_results) && @item.save_trigger_results
      @item.save_trigger_results['log'] =
        results
    end
    results
  end

  private

  #
  # Extract configuration from the model_def, handling both simple and named formats
  # @param [Hash] model_def - either { message: 'x' } or { name: { message: 'x' } }
  # @return [Hash] - the configuration hash
  def extract_config(model_def)
    return model_def unless model_def.is_a?(Hash)

    # Simple format: config is directly provided with message key
    return model_def if model_def.key?(:message)

    # Named format: first value should be a hash config
    first_val = model_def.values.first
    return first_val if first_val.is_a?(Hash)

    # Default to returning the original if we can't determine the format
    model_def
  end
end
