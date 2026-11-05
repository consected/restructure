# frozen_string_literal: true

module CalcActions
  # Collects the condition and value configurations that ConditionalActions evaluates within an option
  # configuration, so that CalcActions::ConditionLinter can check each of them. The locations match the runtime
  # evaluation points: option conditions, valid_if, references, save_action, set_variables, nfs_store can
  # conditions, save / batch / config trigger tasks (including nested tasks) and page layout perspectives.
  #
  # Trigger tasks are interpreted through the OptionConfigs::TriggerTypes descriptors, which declare the keys
  # holding conditions, values and nested tasks for each trigger type.
  class ConditionCollector
    OPTION_CONDITIONS = %i[creatable_if editable_if showable_if add_reference_if].freeze

    # @param configuration [Hash] an option type's configuration, or a page layout's { view_options: {...} }
    # @param path [String, Array] location of the configuration, such as an option type name (may be empty),
    #   or its path keys
    # @param model_class [Class, nil] the class of this record, used to check this: fields when it is known
    # @return [Array<Hash>] entries of the form { condition:, path:, path_keys:, mode:, model_class:,
    #   implied_no_masters: } where path is the dotted location and path_keys the structured location (list indexes
    #   are integers), mode is :condition or :value, and implied_no_masters is true when no_masters: {} was injected
    #   into a perspective rather than written by the admin
    def self.collect(configuration:, path:, model_class:)
      new(model_class:).collect(configuration, CalcActions::ConditionLinter.path_keys(path))
    end

    def initialize(model_class:)
      @model_class = model_class
      @entries = []
    end

    # @param path [Array] the path keys of the configuration
    def collect(configuration, path)
      return [] unless configuration.is_a?(Hash)

      config = configuration.deep_symbolize_keys
      OPTION_CONDITIONS.each { |key| add_condition(config[key], join(path, key)) }
      collect_valid_if(config[:valid_if], join(path, :valid_if))
      collect_references(config[:references], join(path, :references))
      collect_save_action(config[:save_action], join(path, :save_action))
      collect_set_variables(config[:set_variables], join(path, :set_variables))
      collect_nfs_store(config[:nfs_store], join(path, :nfs_store))
      collect_triggers(config, path)
      collect_perspectives(config.dig(:view_options, :perspectives), join(join(path, :view_options), :perspectives)) if
        config[:view_options].is_a?(Hash)
      @entries
    end

    private

    def collect_valid_if(valid_if, path)
      return unless valid_if.is_a?(Hash)

      valid_if.each { |trigger, cond| add_condition(cond, join(path, trigger)) }
    end

    def collect_references(references, path)
      return unless references.is_a?(Hash)

      references.each do |name, reference|
        next unless reference.is_a?(Hash)

        reference_path = join(path, name)
        OPTION_CONDITIONS.each { |key| add_condition(reference[key], join(reference_path, key)) }
        collect_value_map(reference[:add_with], join(reference_path, :add_with))
      end
    end

    # save_action: { on_save: { action_name: { if: ... } } } (or a list of such entries per action)
    def collect_save_action(save_action, path)
      return unless save_action.is_a?(Hash)

      save_action.each do |lifecycle, actions|
        next unless actions.is_a?(Hash)

        actions.each do |action, configs|
          each_indexed(configs, join(join(path, lifecycle), action)) do |item, item_path|
            add_condition(item[:if], join(item_path, :if)) if item.is_a?(Hash)
          end
        end
      end
    end

    def collect_set_variables(set_variables, path)
      return unless set_variables.is_a?(Array)

      set_variables.each_with_index do |item, index|
        next unless item.is_a?(Hash)

        item_path = path + [index]
        add_condition(item[:if], join(item_path, :if))
        add_value(item[:value], join(item_path, :value))
      end
    end

    def collect_nfs_store(nfs_store, path)
      return unless nfs_store.is_a?(Hash) && nfs_store[:can].is_a?(Hash)

      nfs_store[:can].each do |key, cond|
        add_condition(cond, join(join(path, :can), key)) if key.to_s.end_with?('_if')
      end
    end

    def collect_triggers(config, path)
      save_trigger = config[:save_trigger]
      if save_trigger.is_a?(Hash)
        save_trigger.each do |lifecycle, tasks|
          next unless lifecycle.in?(OptionConfigs::ExtraOptions::ValidSaveTriggerTriggers)

          collect_tasks(tasks, join(join(path, :save_trigger), lifecycle))
        end
      end

      collect_tasks(config.dig(:batch_trigger, :on_record), join(join(path, :batch_trigger), :on_record))
      collect_tasks(config.dig(:config_trigger, :on_define), join(join(path, :config_trigger), :on_define))
    end

    # A list of trigger tasks, each a Hash of trigger name to its configuration
    def collect_tasks(tasks, path)
      each_indexed(tasks, path) do |task, task_path|
        next unless task.is_a?(Hash)

        task.each { |name, config| collect_task(name.to_sym, config, join(task_path, name)) }
      end
    end

    def collect_task(name, config, path)
      return if config.nil?

      descriptor = OptionConfigs::TriggerTypes::Base.for(name) || OptionConfigs::TriggerTypes::Base
      collect_task_config(descriptor, config, path)
    end

    def collect_task_config(descriptor, config, path)
      if config.is_a?(Array)
        return collect_tasks(config, path) if descriptor.task_list_config?

        return config.each_with_index { |item, index| collect_task_config(descriptor, item, path + [index]) }
      end
      return unless config.is_a?(Hash)
      return collect_tasks([config], path) if descriptor.task_list_config?

      collect_direct(descriptor, config, path)
      collect_named_entries(descriptor, config, path) if named_entry_form?(descriptor, config)
    end

    # named_entry triggers wrap each configuration in a label, such as create_reference: { my_ref: { if: ... } }
    def collect_named_entries(descriptor, config, path)
      config.each do |label, body|
        next if label.to_sym.in?(descriptor_keys(descriptor))
        next unless body.is_a?(Hash)

        collect_direct(descriptor, body, join(path, label))
      end
    end

    def named_entry_form?(descriptor, config)
      return false unless descriptor.pattern == :named_entry

      direct_keys = Array(descriptor.allowed_keys) - %i[if on_complete on_failure]
      config.keys.none? { |key| key.to_sym.in?(direct_keys) }
    end

    def descriptor_keys(descriptor)
      descriptor.condition_keys + descriptor.value_keys + descriptor.value_map_keys + descriptor.task_keys
    end

    def collect_direct(descriptor, body, path)
      descriptor.condition_keys.each { |key| add_condition(body[key], join(path, key)) if body.key?(key) }
      descriptor.value_keys.each { |key| add_value(body[key], join(path, key)) if body.key?(key) }
      descriptor.value_map_keys.each { |key| collect_value_map(body[key], join(path, key)) if body.key?(key) }
      descriptor.task_keys.each { |key| collect_tasks(body[key], join(path, key)) if body.key?(key) }
    end

    # Each value within a field => value map is evaluated as a value expression.
    # embedded_item is special: its inner values are evaluated one by one (see SaveTriggersBase#handle_with_attributes)
    def collect_value_map(map, path)
      return unless map.is_a?(Hash)

      map.each do |field, value|
        if field == :embedded_item && value.is_a?(Hash)
          value.each { |inner_field, inner_value| add_value(inner_value, join(join(path, field), inner_field)) }
        else
          add_value(value, join(path, field))
        end
      end
    end

    # Values from a page layout's perspectives. conditional_calculation runs in value mode with no_masters
    # injected, as ActivityLog::Perspectives::Runner does.
    def collect_perspectives(perspectives, path)
      return unless perspectives.is_a?(Hash)

      perspectives.each do |resource, items|
        each_indexed(items, join(path, resource)) do |item, item_path|
          next unless item.is_a?(Hash) && item[:conditional_calculation].is_a?(Hash)

          calc = item[:conditional_calculation]
          implied = !calc[:no_masters]
          calc = calc.merge(no_masters: {}) if implied
          add(calc, join(item_path, :conditional_calculation), :value, implied_no_masters: implied)
        end
      end
    end

    # Yields each item of a list, or a single item, with the path identifying its position
    def each_indexed(items, path)
      return if items.nil?

      if items.is_a?(Array)
        items.each_with_index { |item, index| yield item, path + [index] }
      else
        yield items, path
      end
    end

    def add_condition(cond, path)
      add(cond, path, :condition) unless cond.nil?
    end

    def add_value(value, path)
      add(value, path, :value) if value.is_a?(Hash)
    end

    def add(cond, path, mode, implied_no_masters: false)
      @entries << { condition: cond, path: CalcActions::ConditionLinter.dotted_path(path), path_keys: path,
                    mode:, model_class: @model_class, implied_no_masters: }
    end

    def join(path, key)
      path + [key.is_a?(Integer) ? key : key.to_s]
    end
  end
end
