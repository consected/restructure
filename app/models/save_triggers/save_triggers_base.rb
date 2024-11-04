# frozen_string_literal: true

# Base class for save triggers
class SaveTriggers::SaveTriggersBase
  attr_accessor :config, :user, :item, :master, :model_defs, :this_config, :in_master

  def initialize(config, item)
    self.config = config
    raise FphsException, 'save_trigger configuration must be a Hash' unless config.is_a?(Hash) || config.is_a?(Array)

    raise FphsException, 'save_trigger item must be set' unless item

    self.item = item
    self.master = item.master if item.respond_to? :master
    item.save_trigger_results ||= {} if item.respond_to? :save_trigger_results

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
      ca = ConditionalActions.new with_result[:from], @item
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

  def self.config_def(if_extras: nil); end
end
