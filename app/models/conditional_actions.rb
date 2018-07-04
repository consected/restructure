class ConditionalActions

  include CalcActions
  attr_accessor :current_instance, :action_conf, :return_failures, :current_scope, :condition_config, :this_val


  def initialize action_conf, current_instance, return_failures: nil, current_scope: nil
    @action_conf = action_conf
    @current_instance = current_instance
    @return_failures = return_failures

    # For the lowest level, setup the query with the master record
    # If current_scope is specified, then we are at a sub condition level, and the
    # scope supplied should be used instead
    @current_scope = current_scope || Master.select(:id).where(id: current_instance.master.id)
  end

  def calc_action_if
    do_calc_action_if
  end

  # Get the value of a field with expected value set as 'return_value'
  # Since we are only trying to return a single field value, no :all is needed on the configuration
  def get_this_val
    @action_conf = {all: @action_conf}
    do_calc_action_if
    return @this_val
  end

  # Calculate the save actions to return for the front end to process
  # Returns a set of results like:
  # {
  #   on_save: { action_name: <config hash or string>, ... },
  #   on_create: { action_name: <config hash or string>, ... },
  #   on_update: { action_name: <config hash or string>, ... }
  # }
  # Items that either have no 'if' condition, or are true are kept.
  # Condional failures are not returned.

  # Note that this is not just used by save_action, but also save_trigger
  def calc_save_action_if
    sa = @action_conf

    if sa.is_a? Hash
      res = {}
      return unless sa.first
      if sa.first.last.is_a? String
        return {sa.first.first => {sa.first.last => true}}
      else
        sa.each do |on_act, conf|
          conf.each do |do_act, conf_act|
            if conf_act[:if]
              ca = ConditionalActions.new conf_act[:if], @current_instance
              succ = ca.calc_action_if
            else
              succ = true
            end
            if succ
              res[on_act] ||= {}
              if conf_act[:value]
                res[on_act].merge!( do_act => conf_act[:value] )
              else
                res[on_act][do_act] = true
              end
            end
          end
        end
      end
    end
    res
  end


end
