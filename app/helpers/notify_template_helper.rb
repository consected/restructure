# frozen_string_literal: true

module NotifyTemplateHelper
  SAVE_TRIGGER_KEYS = %i[on_create on_update on_upload on_disable before_save].freeze
  TEMPLATE_CONFIG_KEYS = { layout_template: 'layout', content_template: 'content' }.freeze
  TASK_LIFECYCLE_KEYS = %w[on_complete on_failure do then else].freeze

  # Collect unique layout and content templates referenced by notify save and batch triggers.
  # @param object_instance [Object] a dynamic definition with option configurations
  # @return [Array<Hash>] notify template reference details
  def notify_template_references_for(object_instance)
    references = Array(object_instance.option_configs).flat_map do |option_config|
      save_trigger = option_config.save_trigger
      save_references = SAVE_TRIGGER_KEYS.flat_map do |trigger_key|
        collect_notify_template_references(save_trigger&.public_send(trigger_key)&.tasks)
      end
      batch_references = collect_notify_template_references(option_config.batch_trigger&.on_record&.tasks)

      save_references + batch_references
    end

    references.uniq { |reference| [reference[:template_type], reference[:name], reference[:message_type]] }
  end

  private

  # Walks a trigger task list, descending only into notify tasks, delegate trigger
  # tasks and lifecycle hooks, so that trigger data (e.g. an update_this field named
  # notify) is not mistaken for a notify task.
  def collect_notify_template_references(tasks)
    case tasks
    when Hash
      tasks.flat_map do |trigger_name, config|
        if TASK_LIFECYCLE_KEYS.include?(trigger_name.to_s) || delegate_trigger?(trigger_name)
          collect_notify_template_references(config)
        elsif trigger_name.to_s == 'notify'
          notify_template_references_from(config) + collect_lifecycle_references(config)
        else
          collect_lifecycle_references(config)
        end
      end
    when Array
      tasks.flat_map { |entry| collect_notify_template_references(entry) }
    else
      []
    end
  end

  def delegate_trigger?(trigger_name)
    OptionConfigs::TriggerTypes::Base.for(trigger_name)&.pattern == :delegate
  end

  def collect_lifecycle_references(config)
    case config
    when Array
      config.flat_map { |entry| collect_lifecycle_references(entry) }
    when Hash
      config.flat_map do |key, value|
        TASK_LIFECYCLE_KEYS.include?(key.to_s) ? collect_notify_template_references(value) : []
      end
    else
      []
    end
  end

  def notify_template_references_from(configurations)
    configurations = [configurations] unless configurations.is_a?(Array)

    configurations.flat_map do |configuration|
      next [] unless configuration.is_a?(Hash)

      message_type = notify_message_type(configuration)
      TEMPLATE_CONFIG_KEYS.filter_map do |key, template_type|
        value = configuration.key?(key) ? configuration[key] : configuration[key.to_s]
        next if value.nil? || (value.is_a?(String) && value.empty?)

        literal = value.is_a?(String) && value.exclude?('{{')
        name = value.is_a?(String) ? value : value.inspect
        { template_type:, name:, message_type:, literal: }
      end
    end
  end

  def notify_message_type(configuration)
    type = configuration.key?(:type) ? configuration[:type] : configuration['type']
    return unless type.is_a?(String) || type.is_a?(Symbol)
    return if type.to_s.include?('{{')

    message_type = type.to_s.downcase
    message_type if Messaging::MessageNotification::ValidMessageTypes.include?(message_type)
  end
end
