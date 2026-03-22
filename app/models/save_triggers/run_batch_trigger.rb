# frozen_string_literal: true

#
# Save trigger to run a batch trigger in another dynamic model.
# This allows a save action to trigger batch processing in related views or models,
# useful for picking up items that may have been missed in other triggers or API calls.
#
# Example configuration:
#   save_trigger:
#     on_create:
#       run_batch_trigger:
#         resource_name: dynamic_model__view_handle_recs
#         mode: foreground | background
#         limit: 100
#         if: { ... }
#
class SaveTriggers::RunBatchTrigger < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super

    @model_defs = config
  end

  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    results = []
    @model_defs.each do |model_def|
      # Handle both simple format { resource_name: 'x', mode: 'y' }
      # and named format { batch_1: { resource_name: 'x', mode: 'y' } }
      config = extract_config(model_def)
      with_entry_lifecycle(config) do
        # Evaluate conditional if
        if config[:if]
          ca = ConditionalActions.new config[:if], @item
          next unless ca.calc_action_if
        end

        resource_name = config[:resource_name]
        raise FphsException, 'run_batch_trigger requires resource_name to be specified' if resource_name.blank?

        mode = config[:mode] || 'foreground'
        limit = config[:limit]

        # Resolve the resource to get the model class
        resource = Resources::Models.find_by(resource_name: resource_name.to_sym)
        raise FphsException, "run_batch_trigger could not find resource: #{resource_name}" unless resource

        model_class = resource.model
        raise FphsException, "run_batch_trigger resource has no model class: #{resource_name}" unless model_class

        # Verify the model supports batch triggers
        unless model_class.respond_to?(:trigger_batch) && model_class.respond_to?(:trigger_batch_now)
          raise FphsException,
                "run_batch_trigger resource does not support batch triggers: #{resource_name}"
        end

        alt_user = @item.current_user

        Rails.logger.info "run_batch_trigger: #{mode} batch for #{resource_name} with limit #{limit}"

        case mode.to_s
        when 'background'
          model_class.trigger_batch(limit:, alt_user:)
          results << { resource_name:, mode:, status: 'queued' }
        when 'foreground'
          ids = model_class.trigger_batch_now(limit:, alt_user:)
          results << { resource_name:, mode:, status: 'completed', processed_ids: ids }
        else
          raise FphsException, "run_batch_trigger mode must be 'foreground' or 'background', got: #{mode}"
        end
      end
    end

    # Store results for potential use by subsequent triggers
    if @item.respond_to?(:save_trigger_results) && @item.save_trigger_results
      @item.save_trigger_results['run_batch_trigger'] =
        results
    end
    results
  end

  private

  #
  # Extract configuration from the model_def, handling both simple and named formats
  # @param [Hash] model_def - either { resource_name: 'x' } or { name: { resource_name: 'x' } }
  # @return [Hash] - the configuration hash
  def extract_config(model_def)
    return model_def unless model_def.is_a?(Hash)

    # Simple format: config is directly provided with resource_name key
    return model_def if model_def.key?(:resource_name)

    # Named format: first value should be a hash config
    first_val = model_def.values.first
    return first_val if first_val.is_a?(Hash)

    # Default to returning the original if we can't determine the format
    model_def
  end
end
