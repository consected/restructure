module CalcActions

  extend ActiveSupport::Concern

  included do
    SelectionTypes = :all, :any, :not_all, :not_any
  end

  def calc_action_if action_conf, obj, current_scope=nil
    return true unless action_conf.is_a?(Hash) && action_conf.first

    # For the lowest level, setup the query with the master record
    # If current_scope is specified, then we are at a sub condition level, and the
    # scope supplied should be used instead
    all_res = current_scope || Master.select(:id).where(id: obj.master.id)
    # Final result for all selections
    all_sel_res = true

    return false if action_conf[:never]
    return true if action_conf[:always]

    # calculate that all the following sets of conditions are true:
    # (:all conditions) AND (:not_all conditions) AND (:any conditions) AND (:not_any conditions)
    #
    # selection_type=all|any|not_all|not_any:
    #   table_name:
    #     condition: string|reference_condition
    #   selection_type:
    #     table_name: ...

    action_conf.each do |c_var, c_is_res|
      c_is = {}
      join_tables = []
      c_var = c_var.to_sym

      c_is, join_tables = calc_query_conditions(c_is_res, obj)

      q = all_res.joins(join_tables)

      if c_var == :all
        res = true
        # equivalent of (cond1 AND cond2 AND cond3 ...)
        # These conditions are easy to handle as a standard query
        res_q = q.where(c_is).order(id: :desc).limit(1)
        res_q = calc_sub_conditions(c_is_res, obj, res_q)
        res &&= !!res_q

      elsif c_var == :not_all
        res = true
        # equivalent of NOT(cond1 AND cond2 AND cond3 ...)
        res_q = q.where(c_is).order(id: :desc).limit(1)
        res_q = calc_sub_conditions(c_is_res, obj, res_q)

        res &&= !res_q

      elsif c_var == :any
        res = false
        # equivalent of (cond1 OR cond2 OR cond3 ...)
        c_is.each do |ck, fields|
          fields.each do |cvf, cvk|
            res_q = q.where(ck => {cvf => cvk}).order(id: :desc).limit(1)
            res_q = calc_sub_conditions(c_is_res, obj, res_q)
            res ||= res_q
            break if res
          end
        end


      elsif c_var == :not_any
        res = true
        # equivalent of NOT(cond1 OR cond2 OR cond3 ...)
        # also equivalent to  (NOT(cond1) AND NOT(cond2) AND NOT(cond3))
        c_is.each do |ck, fields|
          fields.each do |cvf, cvk|
            res_q = q.where(ck => {cvf => cvk}).order(id: :desc).limit(1)
            res_q = calc_sub_conditions(c_is_res, obj, res_q)
            res &&= !res_q
            break unless res
          end
        end

      else
        raise FphsException.new "Incorrect condition type specified when calculating action if: #{c_var}"
      end

      all_sel_res &&= res
      break unless all_sel_res
    end


    all_sel_res
  end

  # Generate query conditions and a list of join tables based on a conditional configuration,
  # such as
  # creatable_if:
  #  all:
  #    <creatable conditions>
  #
  def calc_query_conditions condition_config, current_instance
    join_tables = condition_config.keys.map(&:to_sym) - SelectionTypes
    conditions = {}

    condition_config.each do |c_table, t_conds|
      table_name = c_table.gsub('__', '_').gsub('dynamic_model_', '').to_sym

      unless table_name.in? SelectionTypes

        conditions[table_name] ||= {}
        t_conds.each do |field, val|

          if val.is_a? Hash
            val_item_key = val.first.first
            if val_item_key == 'this'
              val = current_instance.attributes[val.first.last]
            elsif val_item_key == 'this_references'
              valset = []
              current_instance.model_references.each do |mr|
                valset << mr.to_record.attributes[val.first.last]
              end
              val = valset
            else
              val_key = val.keys.first
              join_tables << val_key unless join_tables.includes? val_key
            end
          end
          conditions[table_name][field] = val
        end
      end
    end

    return conditions, join_tables
  end

  # Calculate the sub conditions for this level if it contains any of the selection types
  # The condition_type optional argument represents how the individual selection calculations
  # should be combined, based on the parent definition.
  def calc_sub_conditions condition_config, current_instance, current_scope, condition_type=:all

    res = condition_type.in?([:all, :not_any])

    return !res if current_scope.length == 0

    condition_config.each do |c_type, t_conds|

      if c_type.to_sym.in? SelectionTypes

        res_a = calc_action_if( {c_type => t_conds}, current_instance, current_scope)
        if condition_type == :all
          res &&= res_a
          return unless res
        elsif condition_type == :any
          res ||= res_a
          return if res_a
        elsif condition_type == :not_any
          res &&= !res_a
          return unless res
        elsif condition_type == :not_all
          # NOT(cond1 AND cond2 AND cond3)
          # equivalent to (NOT(cond1) OR NOT(cond2) OR NOT(cond3))
          # which allows a simpler step by step evaluation
          res ||= !res_a
          return if res
        else
          raise FphsException.new "Incorrect condition type specified when calculating sub conditions: #{condition_type}"
        end
      end
    end

    return res
  end


end
