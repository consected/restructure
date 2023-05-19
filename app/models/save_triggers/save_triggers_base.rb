# frozen_string_literal: true

# Base class for save triggers
class SaveTriggers::SaveTriggersBase
  attr_accessor :config, :user, :item, :master, :model_defs, :this_config

  def initialize(config, item)
    self.config = config
    raise FphsException, 'save_trigger configuration must be a Hash' unless config.is_a?(Hash) || config.is_a?(Array)

    raise FphsException, 'save_trigger item must be set' unless item

    self.item = item
    self.master = item.master if item.respond_to? :master
    item.save_trigger_results ||= {} if item.respond_to? :save_trigger_results

    if item.respond_to? :current_user
      self.user = item.current_user
      raise FphsException, 'save_trigger item master user must be set' unless user
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

  def self.config_def(if_extras: nil); end
end
