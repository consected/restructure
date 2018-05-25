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
          res_q = calc_query_conditions
          merge_failures({condition_type => condition_config}) if !res_q

          @non_query_conditions.each do |table, fields|
            fields.each do |field_name, expected_val|
              res_q &&= calc_this_condition(table, field_name, expected_val)
              merge_failures({condition_type => {table => {field_name => expected_val}}}) if !res_q
            end
          end
          cond_res &&= !!res_q

        elsif condition_type == :not_all
          cond_res = true
          # equivalent of NOT(cond1 AND cond2 AND cond3 ...)
          calc_query @condition_values
          res_q = calc_query_conditions

          @non_query_conditions.each do |table, fields|
            fields.each do |field_name, expected_val|
              res_q &&= calc_this_condition(table, field_name, expected_val)
            end
          end

          cond_res &&= !res_q

          # Not all matches - return all possible items that failed
          merge_failures({condition_type => @condition_values}) if !cond_res
          merge_failures({condition_type => @non_query_conditions}) if !cond_res


        elsif condition_type == :any
          cond_res = false
          # equivalent of (cond1 OR cond2 OR cond3 ...)
          @condition_values.each do |table, fields|
            fields.each do |field_name, expected_val|
              calc_query(table => {field_name => expected_val})
              res_q = calc_query_conditions
              break if res_q
            end
            break if res_q
          end

          # If no matches - return all possible items that failed
          merge_failures({condition_type => @condition_values}) if !res_q

          unless res_q
            @non_query_conditions.each do |table, fields|
              fields.each do |field_name, expected_val|
                res_q ||= calc_this_condition(table, field_name, expected_val)
                break if res_q
              end
            end
          end

          merge_failures({condition_type => @non_query_conditions}) if !res_q

          cond_res = res_q


        elsif condition_type == :not_any
          cond_res = true
          # equivalent of NOT(cond1 OR cond2 OR cond3 ...)
          # also equivalent to  (NOT(cond1) AND NOT(cond2) AND NOT(cond3))
          @condition_values.each do |table, fields|
            fields.each do |field_name, expected_val|
              unless table == :this
                calc_query(table => {field_name => expected_val})
                res_q = calc_query_conditions
              end
              merge_failures({condition_type => {table => {field_name => expected_val}}}) if res_q
              cond_res &&= !res_q
              break unless cond_res && !return_failures
            end
            break unless cond_res && !return_failures
          end

          @non_query_conditions.each do |table, fields|
            fields.each do |field_name, expected_val|

              cond_res &&= !calc_this_condition(table, field_name, expected_val)
              merge_failures({condition_type => {field_name => expected_val}}) if res_q

            end
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

      if table == :this
        if expected_val.is_a? Hash
          if expected_val.keys.first.in? validation_types
            calc_complex_validation expected_val, current_instance.attributes[field_name.to_s]
          end
        else
          current_instance.attributes[field_name.to_s] == expected_val
        end
      end
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
      @non_query_conditions = {}

      @condition_config.each do |c_table, t_conds|
        table_name = ModelReference.record_type_to_table_name(c_table).to_sym

        unless table_name.in? SelectionTypes

          t_conds.each do |field_name, val|

            non_query_condition = table_name == :table
            if val.is_a? Hash
              val_item_key = val.first.first
              if val_item_key == :this
                non_query_condition = true
                val = @current_instance.attributes[val.first.last]
              elsif val_item_key == :this_references
                non_query_condition = true
                val = []
                # Get the specified attribute's value from each of the model references
                # Generate an array, allowing the conditions to be IN any of these
                @current_instance.model_references.each do |mr|
                  val << mr.to_record.attributes[val.first.last]
                end
              else
                val.keys.each do |val_key|
                  if val_key.in? validation_types
                    non_query_condition = true
                  else
                    join_tables << val_key unless join_tables.include? val_key
                  end
                end
              end
            end
            unless non_query_condition
              @condition_values[table_name] ||= {}
              @condition_values[table_name][field_name] = val
            else
              @non_query_conditions[table_name] ||= {}
              @non_query_conditions[table_name][field_name] = val
            end
          end
        end
      end
      join_tables = join_tables - [:this, :this_references]

      @base_query = @current_scope.joins(join_tables)
    end

    # Calculate the sub conditions for this level if it contains any of the selection types
    def calc_query_conditions

      res = true

      # The query didn't return a result - therefore the condition evaluates to false
      return false if @condition_scope.length == 0



      # Combine sub condition results if they are specified
      @condition_config.each do |c_type, t_conds|
        # If this is a sub condition (the key is one of :all, :any, :not_any, :not_all)
        # go ahead and calculate the sub conditions results by instantiating a ConditionalActions class
        # with the scope as the current condition scope from the query
        if c_type.to_sym.in? SelectionTypes
          ca = ConditionalActions.new({c_type => t_conds}, current_instance, current_scope: @condition_scope, return_failures: return_failures)
          res_a = ca.calc_action_if
          res &&= res_a
          return unless res
        end
      end

      return res
    end


    def validation_types
      %i(min_length max_length)
    end

    def calc_complex_validation condition, value
      res = true
      condition.each do |k, opts|
        validator_class = Validates.const_get("#{k.to_s.classify}Validator")
        v = validator_class.new k=>opts, attributes: {_attr: value}
        res &&= v.value_is_valid? value
      end

      res
    end


end
