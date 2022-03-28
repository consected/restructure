# frozen_string_literal: true

class ConditionalActions
  include CalcActions
  attr_accessor :current_instance, :action_conf, :return_failures, :current_scope, :condition_config, :this_val

  def initialize(action_conf, current_instance, return_failures: nil, current_scope: nil)
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
  def calc_save_option_if
    sa = @action_conf

    if sa.is_a? Hash
      res = {}
      return unless sa.first
      if sa.first.last.is_a? String
        return { sa.first.first => { sa.first.last => true } }
      else
        sa.each do |on_act, conf|
          conf.each do |do_act, conf_act|
            if conf_act.is_a? Hash
              if conf_act[:if]
                ca = ConditionalActions.new conf_act[:if], @current_instance
                succ = ca.calc_action_if
              else
                succ = true
              end
              if succ
                res[on_act] ||= {}
                if conf_act[:value]
                  res[on_act].merge!(do_act => conf_act[:value])
                else
                  res[on_act][do_act] = true
                end
              end
            else
              # Default if this was not a Hash definition
              # For example, an array might be used in the create_reference, allowing
              # multiple items to be performed with the same name. This just passes responsibility
              # for checking the condition to the processor
              res[on_act] ||= {}
              res[on_act][do_act] = true
            end
          end
        end
      end
    end
    res
  end
end
