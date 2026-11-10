# frozen_string_literal: true

module OptionConfigs
  # Turns the condition linter's warnings into configuration notices for display alongside the regular
  # configuration errors and warnings of a dynamic definition or page layout.
  #
  # Each notice states the problem as its message, and shows the configuration snippet around it as config_def:
  # the configuration from its top-level key down to the offending key.
  #
  # Linting is non-blocking: notices only inform the administrator, and never prevent a save.
  # If the linter itself raises, a single 'condition linter failed' notice is returned instead.
  module ConditionLintNotices
    WARNING_TYPE = 'condition configuration'
    FAILURE_TYPE = 'condition linter failed'

    # @param object_instance [Object] a dynamic definition, activity log, external identifier or page layout
    # @return [Array<Hash>] configuration notices, empty when there is nothing to report
    def self.for(object_instance)
      found = collect_entries(object_instance).flat_map do |entry|
        linter = CalcActions::ConditionLinter.new(condition: entry[:condition], path: entry[:path_keys],
                                                  model_class: entry[:model_class], mode: entry[:mode],
                                                  implied_no_masters: entry.fetch(:implied_no_masters, false))
        linter.lint.map { |notice| { entry:, notice: } }
      end
      unique_notices(found).map { |item| warning_notice(object_instance, item) }
    rescue StandardError => e
      Rails.logger.error "#{FAILURE_TYPE} for #{object_instance.class.name}: #{e}"
      Rails.logger.error e.backtrace&.first(10)&.join("\n")
      [failure_notice(object_instance, e)]
    end

    # Inherited conditions (from _default, _merge_default or _override) are merged into every option type,
    # so the same problem is linted once per option type. Keep one notice per location within the option
    # configurations, ignoring the option type prefix, so that different locations are still reported.
    # @param found [Array<Hash>] the entry and linter notice for each notice
    # @return [Array<Hash>] the found items, without duplicates
    def self.unique_notices(found)
      found.uniq { |item| [relative_path_keys(item), item[:notice][:message]] }
    end

    # The path keys of a notice, without the option type that prefixes the path keys of an option configuration
    def self.relative_path_keys(item)
      prefix = item[:entry][:option] ? 1 : 0
      item[:notice][:path_keys].drop(prefix)
    end

    # Collect the condition and value configurations for the object, with their paths, modes and the
    # configuration (source) that the paths locate within
    # @return [Array<Hash>]
    def self.collect_entries(object_instance)
      if object_instance.is_a?(Admin::PageLayout)
        source = { 'view_options' => object_instance.view_options&.to_h }.deep_stringify_keys
        return CalcActions::ConditionCollector.collect(configuration: source, path: [], model_class: nil)
                                              .map { |entry| entry.merge(source:) }
      end
      return [] unless object_instance.respond_to?(:option_configs)

      model_class = model_class_for(object_instance)
      Array(object_instance.option_configs).flat_map do |option_config|
        next [] unless option_config.respond_to?(:orig_config)

        option = option_config.name.to_s
        source = { option => option_config.orig_config }.deep_stringify_keys
        CalcActions::ConditionCollector.collect(configuration: option_config.orig_config,
                                                path: [option], model_class:)
                                       .map { |entry| entry.merge(option:, source:) }
      end
    end

    # The class of this record, used to check this: fields. Unknown classes skip those checks.
    def self.model_class_for(object_instance)
      object_instance.respond_to?(:model_class) ? object_instance.model_class : nil
    end

    # The notice shows the configuration snippet around the problem, rather than its location in the message
    def self.warning_notice(object_instance, item)
      build_notice(object_instance, WARNING_TYPE, item[:notice][:message],
                   config_def: config_snippet(item[:entry][:source], item[:notice][:path_keys]))
    end

    # The configuration from the top-level key down to the offending key, holding the offending value.
    # A list index is shown as a one-element list. A key that is not in the configuration (such as one implied
    # at runtime, or a condition inherited from _default) is shown with its value omitted.
    # @param source [Hash] the stringified configuration, with its top-level key
    # @param path_keys [Array<String, Integer>] the location of the offending key within the source
    # @return [Hash, Array, nil]
    def self.config_snippet(source, path_keys)
      snippet_at(source, path_keys)
    end

    def self.snippet_at(node, path_keys)
      return node if path_keys.empty?

      key, *rest = path_keys
      found, child = lookup(node, key)
      wrap(key, snippet_at(found ? child : nil, rest))
    end

    def self.lookup(node, key)
      if key.is_a?(Integer)
        return [false, nil] unless node.is_a?(Array) && key < node.length

        [true, node[key]]
      elsif node.is_a?(Hash) && node.key?(key.to_s)
        [true, node[key.to_s]]
      else
        [false, nil]
      end
    end

    def self.wrap(key, value)
      key.is_a?(Integer) ? [value] : { key.to_s => value }
    end

    def self.failure_notice(object_instance, error)
      build_notice(object_instance, FAILURE_TYPE, "Condition linter failed: #{error.message}")
    end

    def self.build_notice(object_instance, type, message, config_def: {})
      OptionConfigs::ConfigErrors.configuration_notice(
        config_obj: object_instance,
        type:,
        message:,
        name: object_instance.try(:name).presence || object_instance.try(:panel_label).presence ||
              object_instance.class.name,
        resource_name: object_instance.try(:resource_name),
        config_def:
      )
    end

    private_class_method :collect_entries, :model_class_for, :unique_notices, :relative_path_keys,
                         :warning_notice, :config_snippet, :snippet_at, :lookup, :wrap,
                         :failure_notice, :build_notice
  end
end
