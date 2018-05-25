module CalcActions

  extend ActiveSupport::Concern

  included do
    SelectionTypes = :all, :any, :not_all, :not_any
    attr_accessor :condition_scope
  end

  private

    def do_calc_action_if
      return true unless action_conf.is_a?(Hash) && action_conf.first

      # Final result for all selections
      final_res = true

      action_conf.symbolize_keys!

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

      action_conf.each do |condition_type, condition_config|
        @condition_config = condition_config

        calc_base_query

        if condition_type == :all
          cond_res = true
          # equivalent of (cond1 AND cond2 AND cond3 ...)
          # These conditions are easy to handle as a standard query
          calc_query @condition_values
          res_q = calc_sub_conditions
          merge_failures({condition_type => condition_config}) if !res_q

          @condition_values.each do |table, fields|
            fields.each do |field_name, expected_val|
              if table == :this
                res_q &&= calc_this_condition(table, field_name, expected_val)
                merge_failures({condition_type => {table => {field_name => expected_val}}}) if !res_q
              end
            end
          end
          cond_res &&= !!res_q

        elsif condition_type == :not_all
          cond_res = true
          # equivalent of NOT(cond1 AND cond2 AND cond3 ...)
          calc_query @condition_values
          res_q = calc_sub_conditions
          @condition_values.each do |table, fields|
            fields.each do |field_name, expected_val|
              res_q &&= calc_this_condition(table, field_name, expected_val) if table == :this
            end
          end
          cond_res &&= !res_q

          # Not all matches - return all possible items that failed
          merge_failures({condition_type => @condition_values}) if !cond_res


        elsif condition_type == :any
          cond_res = false
          # equivalent of (cond1 OR cond2 OR cond3 ...)
          @condition_values.each do |table, fields|
            fields.each do |field_name, expected_val|
              if table == :this
                res_q = calc_this_condition(table, field_name, expected_val)
              else
                calc_query(table => {field_name => expected_val})
                res_q = calc_sub_conditions
              end
              cond_res ||= res_q
              break if cond_res
            end
            break if cond_res
          end

          # If no matches - return all possible items that failed
          merge_failures({condition_type => @condition_values}) if !cond_res

        elsif condition_type == :not_any
          cond_res = true
          # equivalent of NOT(cond1 OR cond2 OR cond3 ...)
          # also equivalent to  (NOT(cond1) AND NOT(cond2) AND NOT(cond3))
          @condition_values.each do |table, fields|
            fields.each do |field_name, expected_val|
              if table == :this
                res_q = calc_this_condition(table, field_name, expected_val)
              else
                calc_query(table => {field_name => expected_val})
                res_q = calc_sub_conditions
              end
              merge_failures({condition_type => {table => {field_name => expected_val}}}) if res_q

              cond_res &&= !res_q
              break unless cond_res unless return_failures
            end
            break unless cond_res unless return_failures
          end

        else
          raise FphsException.new "Incorrect condition type specified when calculating action if: #{condition_type}"
        end

        final_res &&= cond_res
        break unless final_res
      end


      final_res
    end

    def merge_failures results
      if return_failures
        return_failures.deep_merge!(results)
      end
    end


    def calc_query conditions
      @condition_scope = @base_query.where(conditions).order(id: :desc).limit(1)
    end

    def calc_this_condition table, field_name, expected_val
      current_instance.attributes[field_name.to_s] == expected_val
    end

    # Generate query conditions and a list of join tables based on a conditional configuration,
    # such as
    # creatable_if:
    #  all:
    #    <creatable conditions>
    #
    def calc_base_query

      join_tables = @condition_config.keys.map(&:to_sym) - SelectionTypes
      @condition_values = {}

      @condition_config.each do |c_table, t_conds|
        table_name = ModelReference.record_type_to_table_name(c_table).to_sym

        unless table_name.in? SelectionTypes

          @condition_values[table_name] ||= {}
          t_conds.each do |field_name, val|

            if val.is_a? Hash
              val_item_key = val.first.first
              if val_item_key == :this
                val = @current_instance.attributes[val.first.last]
              elsif val_item_key == :this_references
                valset = []
                @current_instance.model_references.each do |mr|
                  valset << mr.to_record.attributes[val.first.last]
                end
                val = valset
              else
                val_key = val.keys.first
                join_tables << val_key unless join_tables.include? val_key
              end
            end
            @condition_values[table_name][field_name] = val
          end
        end
      end
      join_tables = join_tables - [:this, :this_references]

      @base_query = @current_scope.joins(join_tables)
    end

    # Calculate the sub conditions for this level if it contains any of the selection types
    def calc_sub_conditions

      res = true

      return false if @condition_scope.length == 0

      @condition_config.each do |c_type, t_conds|

        if c_type.to_sym.in? SelectionTypes

          ca = ConditionalActions.new({c_type => t_conds}, current_instance, current_scope: @condition_scope, return_failures: return_failures)
          res_a = ca.calc_action_if

          res &&= res_a
          return unless res
        end
      end

      return res
    end


end
