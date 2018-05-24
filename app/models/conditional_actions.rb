class ConditionalActions

  include CalcActions
  attr_accessor :current_instance, :action_conf, :return_failures, :current_scope


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
            if conf_act['if']
              ca = ConditionalActions.new conf_act['if'].symbolize_keys, @current_instance
              succ = ca.calc_action_if
            else
              succ = true
            end
            if succ
              res[on_act] ||= {}
              if conf_act['value']
                res[on_act].merge!( do_act => conf_act['value'] )
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
