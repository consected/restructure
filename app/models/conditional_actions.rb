# frozen_string_literal: true

class ConditionalActions
  include CalcActions
  attr_accessor :current_instance, :action_conf, :return_failures, :current_scope, :condition_config, :this_val

  def initialize(action_conf, current_instance, return_failures: nil, current_scope: nil)
    action_conf = action_conf.symbolize_keys if action_conf.is_a?(Hash)
    @action_conf = action_conf
    @current_instance = current_instance
    @return_failures = return_failures

    # For the lowest level, setup the query with the master record
    # If current_scope is specified, then we are at a sub condition level, and the
    # scope supplied should be used instead
    @current_scope = if !current_instance.class.respond_to?(:no_master_association) ||
                        current_instance.class.no_master_association
                       current_instance.class
                     else
                       current_scope || Master.select(:id).where(id: current_instance.master.id)
                     end
  end

  def calc_action_if
    res = do_calc_action_if
    Rails.logger.debug "******** calc_action_if result: #{res}" if Rails.env.debug?
    res
  end

  # Get the value of a field with expected value set as 'return_value'
  # Since we are only trying to return a single field value, no :all is needed on the configuration
  def get_this_val
    @action_conf = { all: @action_conf }
    do_calc_action_if
    @this_val
  end

  # If the condition supplied is a Hash, attempt to calculate the result_value
  # Otherwise just return the provided value
  # @param cond [Hash | Class] A condition definition with a result_value defined, or just a literal value
  # @param item [UserBase] An object to test against
  def self.calc_field_or_return(cond, item)
    if cond.is_a? Hash
      action_conf = cond
      ca = ConditionalActions.new action_conf, item
      ca.get_this_val
    else
      cond
    end
  end

  #
  # Calculate the save actions to return, for the front end to process
  # or backend triggers to handle.
  # The type being assessed is purely based on the config the ConditionalActions
  # is instantiated with. For example, the following will assess save_trigger options:
  #
  #     save_trigger = obj.extra_options.save_trigger
  #     ca = ConditionalActions.new save_trigger, obj
  #     res = ca.calc_save_option_if
  #
  # Returns a set of results like:
  # {
  #   on_save: { action_name: <config hash or string>, ... },
  #   on_create: { action_name: <config hash or string>, ... },
  #   on_update: { action_name: <config hash or string>, ... }
  # }
  # Items that either have no 'if' condition, or are true are kept.
  # Conditional failures are not returned.
  #
  # If the *check_action_if* param is not set (default), typically by
  # a save trigger like create_reference, allow
  # multiple items to be performed with the same name.
  # This just passes responsibility for checking the condition to the processor.
  # If the *check_action_if* param is set, the if condition
  # for each action will be checked.
  #  - When the definition includes the value: key
  #    then the value for the first successful condition for each action will be returned.
  #    This allows save_actions to return an actual value, rather than just success / fail
  #  - When the definition does not include the value: key
  #    then true will be returned for the action if any conditions match
  #
  # @param [true | nil] check_action_if - default not set
  # @return [Hash | nil | Object] - returns:
  #                                   Hash of results for {on_save:, on_create:, on_update:}
  #                                   nil if the Hash has no entries
  #                                   the original configuration if not a Hash
  def calc_save_option_if(check_action_if: nil)
    sa = @action_conf
    res = {}

    return sa unless sa.is_a? Hash

    return unless sa.first

    return { sa.first.first => { sa.first.last => true } } if sa.first.last.is_a? String

    sa.each do |on_act, conf|
      conf.each do |do_act, conf_acts|
        unless check_action_if
          res[on_act] ||= {}
          res[on_act][do_act] = true
          next
        end
        conf_acts = { value: conf_acts } unless conf_acts.respond_to?(:each)
        conf_acts = [conf_acts] unless conf_acts.is_a? Array

        conf_acts.each do |conf_act|
          if conf_act[:if]
            ca = ConditionalActions.new conf_act[:if], @current_instance
            succ = ca.calc_action_if
          else
            succ = true
          end
          next unless succ

          res[on_act] ||= {}
          res[on_act][do_act] = if conf_act.key? :value
                                  conf_act[:value]
                                else
                                  true
                                end
          break
        end
      end
    end

    res
  end
end
