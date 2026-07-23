# frozen_string_literal: true

# Base class for save triggers
class SaveTriggers::SaveTriggersBase
  attr_accessor :config, :user, :item, :master, :model_defs, :this_config, :in_master

  def initialize(config, item)
    # Normalize first to produce a locally owned plain-Ruby copy.
    # This prevents any mutations from affecting shared/memoized option config
    # data (e.g. the memoized @option_configs hash on definition objects).
    config = normalize_trigger_config(config)

    # Now safely extract and delete lifecycle hooks from the owned copy.
    on_complete_triggers, on_failure_triggers = extract_lifecycle_hooks(config)

    self.config = config
    raise FphsException, 'save_trigger configuration must be a Hash' unless config.is_a?(Hash) || config.is_a?(Array)

    raise FphsException, 'save_trigger item must be set' unless item

    # Normalize extracted lifecycle hooks so lifecycle dispatch uses the same
    # plain Ruby hashes/arrays as the main trigger config.
    @on_complete_triggers = normalize_trigger_config(on_complete_triggers)
    @on_failure_triggers = normalize_trigger_config(on_failure_triggers)

    self.item = item
    self.master = item.master if item.respond_to? :master
    item.save_trigger_results ||= {} if item.respond_to? :save_trigger_results
    item.trigger_variables ||= {} if item.respond_to? :trigger_variables

    if item.respond_to? :current_user
      cu = item.current_user
      extra_detail = "master: #{master} item: #{item} / #{item.class.no_master_association}"
      raise FphsException, "save_trigger item current user not set - #{extra_detail}" unless cu

      self.user = cu
      raise FphsException, "save_trigger item master user must be set - #{extra_detail}" unless user
    end

    self.model_defs = if config.is_a? Array
                        config
                      else
                        [config]
                      end
  end

  #
  # Evaluate the if conditional within a configuration.
  # Returns true if there is no definition, or if it evaluates successfully
  # @param [Hash] if_config
  # @return [True | nil]
  def if_evaluates(if_config)
    return true unless if_config

    ca = ConditionalActions.new if_config, @item
    ca.calc_action_if
  end

  def handle_with_result(with_results, vals)
    return unless with_results

    with_results = [with_results] unless with_results.is_a? Array

    with_results.each do |with_result|
      wr_from = with_result[:from]

      # Allow simple use of 'embedded_item' or 'dynamic_model__some_recs'
      if wr_from.is_a? String
        wr_from = {
          wr_from.to_sym => { return: 'return_result' }
        }
      end

      ca = ConditionalActions.new wr_from, @item
      source = ca.get_this_val

      unless source
        raise FphsException, 'with_result.from returns no result - check return: return_result has been specified'
      end

      with_attrs = with_result[:attributes].dup

      create_with_ei = with_attrs.delete(:embedded_item) if with_attrs[:embedded_item]
      vals[:embedded_item] ||= {} if create_with_ei

      with_attrs.each do |to, from|
        sval = if from.is_a?(Hash) || from.include?('{{')
                 FieldDefaults.calculate_default(source, from)
               else
                 source.attributes[from.to_s]
               end

        vals[to] = sval
      end

      create_with_ei&.each do |to, from|
        sval = if from.is_a?(Hash) || from.include?('{{')
                 FieldDefaults.calculate_default(source, from)
               else
                 source.attributes[from.to_s]
               end

        vals[:embedded_item][to] = sval
      end
    end
  end

  def handle_with_attributes(create_with, vals)
    return unless create_with

    create_with = create_with.dup
    create_with_ei = create_with.delete(:embedded_item) if create_with[:embedded_item]
    vals[:embedded_item] ||= {} if create_with_ei

    create_with.each do |fn, def_val|
      res = FieldDefaults.calculate_default @item, def_val
      vals[fn] = res

      if fn.to_sym == :master_id
        self.in_master = Master.find(res)
        in_master.current_user = @item.current_user
      end
    end

    create_with_ei&.each do |fn, def_val|
      res = FieldDefaults.calculate_default @item, def_val
      vals[:embedded_item][fn] = res
    end
  end

  #
  # Perform substitutions for all the values in a sub_config hash
  # The substitutions are performed in place, and returned by value.
  # @param [Hash] sub_config The configuration hash to perform substitutions on
  # @return [Hash] The configuration hash with substituted values
  def substitute_values_in_config(sub_config)
    sub_config.deep_transform_values! do |v|
      FieldDefaults.calculate_default @item, v
    end
  end

  #
  # Execute an array of trigger configurations sequentially.
  # Each trigger config is a Hash like { trigger_name: config_hash }.
  # Trigger names are validated through the central ValidSaveTriggers registry.
  # @param [Array<Hash>] trigger_list - list of trigger configs to execute
  # @param [Array<Symbol>] skip_keys - keys to skip (e.g. :if)
  # @return [Array<Hash>] results from each trigger as { trigger:, result: }
  def execute_trigger_list(trigger_list, skip_keys: [])
    return [] unless trigger_list

    trigger_list = [trigger_list] unless trigger_list.is_a?(Array)
    results = []

    trigger_list.each do |trigger_config|
      next unless trigger_config.is_a?(Hash)

      trigger_config.each do |trigger_name, config|
        trigger_name = trigger_name.to_sym
        next if skip_keys.include?(trigger_name)

        klass = OptionConfigs::ExtraOptions.trigger_class(trigger_name)
        trigger = klass.new(config, @item)
        result = trigger.perform_with_lifecycle
        results << { trigger: trigger_name, result: }
      rescue FphsException => e
        raise FphsException, "#{e.message}. Full config:\n#{String.yaml_dump(trigger_list)}\nTriggering instance: #{@item.class.name}##{@item.id || '(new)'}"
      end
    end

    results
  end

  #
  # Wrap per-entry processing with lifecycle hooks.
  # Extracts on_complete and on_failure from the entry config hash,
  # executes the block, then fires the appropriate lifecycle triggers.
  # This allows each entry in a multi-entry trigger config to have
  # its own on_complete and on_failure hooks.
  # @param [Hash] entry_config - the per-entry configuration hash
  # @yield Block containing the entry's processing logic
  # @return [Object] the result of the block
  def with_entry_lifecycle(entry_config)
    if entry_config.is_a?(Hash)
      on_complete = entry_config.delete(:on_complete)
      on_failure = entry_config.delete(:on_failure)
    end

    result = yield

    execute_lifecycle_triggers(on_complete) if on_complete.present?
    result
  rescue StandardError
    begin
      execute_lifecycle_triggers(on_failure) if on_failure.present?
    rescue StandardError => inner_e
      Rails.logger.error "[SaveTrigger] on_failure trigger itself raised an error: #{inner_e.message}"
    end
    raise
  end

  #
  # Store trigger results on the item for use by subsequent triggers
  # @param [String] key - the result key (e.g. 'case', 'transaction')
  # @param [Object] results - the results to store
  def store_trigger_results(key, results)
    return unless @item.respond_to?(:save_trigger_results) && @item.save_trigger_results

    @item.save_trigger_results[key] = results
  end

  #
  # Perform the trigger with lifecycle hooks.
  # Calls #perform, then fires on_complete triggers on success,
  # or on_failure triggers if an exception is raised.
  # The original exception is re-raised after on_failure triggers execute.
  # @return [Object] the result of #perform
  def perform_with_lifecycle
    result = perform
    fire_on_complete_triggers
    result
  rescue StandardError
    fire_on_failure_triggers
    raise
  end

  def self.config_def(if_extras: nil); end

  private

  def normalize_trigger_config(value)
    return nil if value.nil?

    case value
    when Array
      # Build a new array; never use map! which would mutate the source array.
      value.map { |entry| normalize_trigger_config(entry) }
    when Hash
      # Build and return a fresh hash; never mutate the source hash in-place
      # (value.clear + value.merge! would corrupt shared/memoized configs).
      value.each_with_object({}) do |(key, nested_value), result|
        result[key.to_sym] = normalize_trigger_config(nested_value)
      end
    else
      if value.respond_to?(:filtered_hash)
        normalize_trigger_config(value.filtered_hash)
      elsif value.respond_to?(:conditions)
        normalize_trigger_config(value.conditions)
      elsif value.respond_to?(:symbolize_keys) && !value.is_a?(String)
        normalize_trigger_config(value.symbolize_keys)
      elsif value.respond_to?(:to_h) && !value.is_a?(String)
        normalize_trigger_config(value.to_h)
      else
        value
      end
    end
  end

  #
  # Extract on_complete and on_failure from the config hash for lifecycle processing.
  # These keys are removed from the config so subclass trigger processing
  # does not encounter them when iterating config entries.
  # Only applies to Hash configs; Array configs are left unchanged,
  # so triggers like Notify that use Array configs with per-entry on_complete
  # continue to function correctly.
  # @param [Hash | Array] trigger_config
  def extract_lifecycle_hooks(trigger_config)
    return [nil, nil] unless trigger_config.is_a?(Hash)

    on_complete = trigger_config.delete(:on_complete)
    on_complete ||= trigger_config.delete('on_complete')

    on_failure = trigger_config.delete(:on_failure)
    on_failure ||= trigger_config.delete('on_failure')

    [on_complete, on_failure]
  end

  #
  # Fire on_complete triggers using calc_triggers dispatch.
  # @return [void]
  def fire_on_complete_triggers
    return unless @on_complete_triggers.present?

    execute_lifecycle_triggers(@on_complete_triggers)
  end

  #
  # Fire on_failure triggers using calc_triggers dispatch.
  # Errors within on_failure triggers are logged but do not prevent
  # the original exception from being re-raised.
  # @return [void]
  def fire_on_failure_triggers
    return unless @on_failure_triggers.present?

    execute_lifecycle_triggers(@on_failure_triggers)
  rescue StandardError => e
    Rails.logger.error "[SaveTrigger] on_failure trigger itself raised an error: #{e.message}"
  end

  #
  # Execute lifecycle trigger configurations.
  # Accepts either a Hash (single trigger) or an Array of Hashes.
  # @param [Hash | Array<Hash>] trigger_configs
  def execute_lifecycle_triggers(trigger_configs)
    trigger_configs = [trigger_configs] unless trigger_configs.is_a?(Array)

    trigger_configs.each do |tc|
      next unless tc.is_a?(Hash)

      tc.each do |trigger_name, config|
        klass = OptionConfigs::ExtraOptions.trigger_class(trigger_name)
        trigger = klass.new(config, @item)
        trigger.perform_with_lifecycle
      rescue FphsException => e
        raise FphsException, "#{e.message}. Full config:\n#{String.yaml_dump(trigger_configs)}\nTriggering instance: #{@item.class.name}##{@item.id || '(new)'}"
      end
    end
  end
end
