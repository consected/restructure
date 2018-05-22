module CalcActions

  extend ActiveSupport::Concern


    def calc_action_if action_conf, obj
      return true unless action_conf.is_a?(Hash) && action_conf.first
      all_res = Master.select(:id).where(id: obj.master.id)
      res = true

      return false if action_conf[:never]
      return true if action_conf[:always]

      # calculate that all the following sets of conditions are true:
      # (:all conditions) AND (:not_all conditions) AND (:any conditions) AND (:not_any conditions)
      action_conf.each do |c_var, c_is_res|
        c_is = {}
        join_tables = []

        c_is, join_tables = calc_query_conditions(c_is_res, obj)

        q = all_res.joins(join_tables)

        c_var = c_var.to_sym
        if c_var == :all
          # equivalent of (cond1 AND cond2 AND cond3 ...)
          # These conditions are easy to handle as a standard query
          res &&= !!q.where(c_is).order(id: :desc).first
          
        elsif c_var == :not_all
          # equivalent of NOT(cond1 AND cond2 AND cond3 ...)
          res &&= !q.where(c_is).order(id: :desc).first

        elsif c_var == :any
          # equivalent of (cond1 OR cond2 OR cond3 ...)
          c_is.each do |ck, cv|
            res = q.where(ck => cv).order(id: :desc).first
            break if res
          end

        elsif c_var == :not_any
          # equivalent of NOT(cond1 OR cond2 OR cond3 ...)
          # also equivalent to  (NOT(cond1) AND NOT(cond2) AND NOT(cond3))
          c_is.each do |ck, cv|
            res &&= !q.where(ck => cv).order(id: :desc).first
            break unless res
          end

        end

        break unless res
      end


      res
    end

    # Generate query conditions and a list of join tables based on a conditional configuration,
    # such as
    # creatable_if:
    #  all:
    #    <creatable conditions>
    #
    def calc_query_conditions condition_config, current_instance
      join_tables = condition_config.keys.map(&:to_sym)
      conditions = {}

      condition_config.each do |c_table, t_conds|
        table_name = c_table.gsub('__', '_').gsub('dynamic_model_', '').to_sym
        conditions[table_name] ||= {}
        t_conds.each do |field, val|

          if val.is_a? Hash

            if val.first.first == 'this'
              val = current_instance.attributes[val.first.last]
            elsif val.first.first == 'this_references'
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

      return conditions, join_tables
    end


end
