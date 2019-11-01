module CalcActions

  extend ActiveSupport::Concern

  include FieldDefaults

  included do
    SelectionTypes = :all, :any, :not_all, :not_any
    BoolTypeString = '__!BOOL__'.freeze
    ValidExtraConditions = ['<', '>', '<>', '<=', '>=', 'LIKE', '~'].freeze
    ValidExtraConditionsArrays = [
      '= ANY', # The value of this field (must be scalar) matches any value from the retrieved array field
      '<> ANY', # The value of this field (must be scalar) must not match any value from the retrieved array field
      '= ARRAY_LENGTH', # The value of this field (must be integer) equals the length of the retrieved array field
      '<> ARRAY_LENGTH', # The value of this field (must be integer) must not equal the length of the retrieved array field
      '= LENGTH', # The value of this field (must be integer) equals the length of the string (varchar or text) field
      '<> LENGTH', # The value of this field (must be integer) must not equal the length of the string (varchar or text) field
      '&&', # Any value of this field (an array) must be in the retrieved array field
      '@>', # This array field contains all of the elements of the retrieved array field
      '<@' # This array field's elements are all found in the retrieved array field
    ].freeze
    attr_accessor :condition_scope, :this_val
  end

  private

    def non_join_table_name? name
       @non_join_table_names ||= %i(this referring_record this_references parent_references validate)
       (name.in?(@non_join_table_names) || is_selection_type(name))
    end

    # Allow the same selection type to be used multiple times, such as:
    # not_any:
    # not_any_2:
    # not_any_3:
    def is_selection_type table_name

      return table_name if table_name.in? SelectionTypes

      SelectionTypes.select {|st| table_name.to_s.start_with? st.to_s}.first
    end

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

      action_conf.each do |condition_type, condition_config_array|
        condition_config_array = [condition_config_array] unless condition_config_array.is_a? Array

        # Provide the option of configuring as a list of conditions, such as:
        # not_any: ...
        # - addresses: ...
        # - addresses: ...
        # all of which must meet the condition type
        orig_cond_type = condition_type
        condition_type = is_selection_type(condition_type) || condition_type
        loop_res = condition_type.in?([:all, :not_any])


        condition_config_array.each do |condition_config|
          @condition_config = condition_config

          if is_selection_type(@condition_config.first.first)
            @condition_config = {this: @condition_config}
          end


          calc_base_query condition_type


          if condition_type == :all
            cond_res = true
            res_q = true
            # equivalent of (cond1 AND cond2 AND cond3 ...)
            # These conditions are easy to handle as a standard query
            # @this_val_where check allows a return_value definition to be used alone without other conditions
            unless @condition_values.empty? && @extra_conditions.empty? && !@this_val_where
              calc_query @condition_values, @extra_conditions
              res_q = calc_query_conditions
              merge_failures({condition_type => @condition_config}) if !res_q
            end

            @non_query_conditions.each do |table, fields|
              fields.each do |field_name, expected_val|
                res_q &&= calc_this_condition(table, field_name, expected_val)
                merge_failures({condition_type => {table => {field_name => expected_val}}}) if !res_q
              end
            end
            cond_res &&= !!res_q

          elsif condition_type == :not_all
            cond_res = true
            res_q = true
            # equivalent of NOT(cond1 AND cond2 AND cond3 ...)
            unless @condition_values.empty? && @extra_conditions.empty?
              calc_query @condition_values, @extra_conditions
              res_q = calc_query_conditions
            end

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

            raise FphsException.new "@extra_conditions not supported with any / not_any conditions" unless @extra_conditions.empty?

            cond_res = false
            res_q = false
            # equivalent of (cond1 OR cond2 OR cond3 ...)
            @condition_values.each do |table, fields|
              fields.each do |field_name, expected_val|
                calc_query({table => {field_name => expected_val}}, @extra_conditions, 'OR')
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

            raise FphsException.new "@extra_conditions not supported with any / not_any conditions" unless @extra_conditions.empty?

            cond_res = true
            # equivalent of NOT(cond1 OR cond2 OR cond3 ...)
            # also equivalent to  (NOT(cond1) AND NOT(cond2) AND NOT(cond3))
            @condition_values.each do |table, fields|
              fields.each do |field_name, expected_val|
                calc_query({table => {field_name => expected_val}}, @extra_conditions, 'OR')
                res_q = calc_query_conditions
                merge_failures({condition_type => {table => {field_name => expected_val}}}) if res_q
                cond_res &&= !res_q
                break unless cond_res && !return_failures
              end
              break unless cond_res && !return_failures
            end

            @non_query_conditions.each do |table, fields|
              fields.each do |field_name, expected_val|

                res_q = !calc_this_condition(table, field_name, expected_val)
                merge_failures({condition_type => {table => {field_name => expected_val}}}) if !res_q
                cond_res &&= res_q
              end
            end

          else
            raise FphsException.new "Incorrect condition type specified when calculating action if: #{condition_type}"
          end

          orig_loop_res = loop_res

          loop_res &&= cond_res if condition_type == :all
          loop_res ||= cond_res if condition_type == :any
          loop_res ||= cond_res if condition_type == :not_all
          loop_res &&= cond_res if condition_type == :not_any
          unless Rails.env.production?
            begin
              Rails.logger.debug "**#{orig_cond_type}*******************************************************************************************************"
              Rails.logger.debug "condition_type: #{condition_type} - loop_res: #{loop_res} - cond_res: #{cond_res} - orig_loop_res: #{orig_loop_res}"
              Rails.logger.debug @condition_config
              Rails.logger.debug @non_query_conditions
              Rails.logger.debug @base_query.to_sql if @base_query
              Rails.logger.debug @condition_scope.to_sql if @condition_scope
              Rails.logger.debug "*********************************************************************************************************"
            rescue => e
              Rails.logger.warn "condition_type: #{condition_type} - loop_res: #{loop_res} - cond_res: #{cond_res} - orig_loop_res: #{orig_loop_res}"
              Rails.logger.warn @condition_config
              Rails.logger.warn @join_tables
              Rails.logger.warn JSON.pretty_generate(@action_conf)
              Rails.logger.warn "Failure in calc_actions: #{e}\n#{e.backtrace.join("\n")}"
              raise e
            end
          end
          break unless loop_res
        end

        final_res &&= loop_res
        break unless final_res
      end


      final_res
    end

    def merge_failures results
      if return_failures && !@skip_merge
        results.first.last.each do |t, res|
          if res.is_a?(Hash) && res.first.last && res.first.last.first.first == :validate
            field = res.first.first
            results.first.last[t] = {field => new_validator(res.first.last[:validate].first.first, nil, options: {}).message }
          end
        end
        return_failures.deep_merge!(results)
      end
    end


    def calc_query conditions, extra_conditions = [], bool = 'AND'

      unless conditions.first && conditions.first.last&.length == 0
        # Conditions are available - apply them as a where clause on top of the base query
        @condition_scope = @base_query.where(conditions)
      else
        # If no conditions are specified for this table, don't apply it as a where clause
        # since it always invalidates the query
        # This typically happens as a result of extra_conditions being applied
        @condition_scope = @base_query
      end
      if extra_conditions.length > 1
        extra_conditions[0].gsub(BoolTypeString, bool)
        @condition_scope = @condition_scope.where(extra_conditions)
      end
      if @this_val_where && @condition_scope.first
        @condition_scope = @condition_scope.order(id: :desc)
        @condition_scope = @condition_scope.limit(1) if @this_val_where[:mode].in? ['return_value', 'return_result']
        all_res = @this_val = @condition_scope.first&.send(@this_val_where[:assoc])
        first_res = all_res.first
        if first_res
          tn = first_res.class.table_name
          fn = first_res.class.attribute_names.select{|s| s == @this_val_where[:field_name].to_s}.first

          tv_tn = UserBase.clean_table_name(ModelReference.record_type_to_table_name(@this_val_where[:table_name]))
          if tn
            rquery = @condition_scope.reorder("#{tn}.id desc")
          elsif tv_tn.present?
            rquery = @condition_scope.reorder("#{tv_tn}.id desc")
          end
          if @this_val_where[:mode] == 'return_result'
            raise "return_result clean table name is blank for (#{@this_val_where[:table_name]})" if tv_tn.blank?
            rquery = rquery.select("#{tv_tn}.*")
            @this_val = first_res.class.find(rquery.first.id)
          else
            rvals = rquery.pluck("#{tn}.#{fn}")
            @this_val = rvals.first if @this_val_where[:mode] == 'return_value'
            @this_val = rvals if @this_val_where[:mode] == 'return_value_list'
          end
        end
      else
        @condition_scope = @condition_scope.order(id: :desc).limit(1)
      end
      @condition_scope
    end

    def calc_this_condition table, field_name, expected_vals
      @skip_merge = false
      # this_val attribute is used to return the last value from a definition. Used for simple lookups

      res = true
      # Allow a list of possible conditions to be used
      expected_vals = [expected_vals] unless expected_vals.is_a?(Array) && expected_vals.first.is_a?(Hash)
      expected_vals.each do |expected_val|


        if field_name == :return_constant
          # The literal value will be returned in this case
          @this_val = expected_val
          return true
        end

        if table == :this || table == :parent || table == :referring_record
          if table == :this
            in_instance = current_instance
          elsif table == :parent
            in_instance = current_instance.parent_item
          elsif table == :referring_record
            in_instance = current_instance.referring_record
          end

          if field_name == :exists
            res = @this_val = (!!expected_val == !!in_instance)
            @skip_merge = true
          elsif !in_instance
            raise FphsException.new "Instance not found for #{table}"
          else

            if expected_val.is_a?(Hash)
              if is_selection_type field_name
                ca = ConditionalActions.new({field_name => expected_val}, in_instance, current_scope: @condition_scope, return_failures: return_failures)
                res &&= ca.calc_action_if
                @this_val ||= ca.this_val
                @skip_merge = true
              elsif expected_val.keys.first == :validate
                res &&= calc_complex_validation expected_val[:validate], in_instance.attributes[field_name.to_s]
              end
            else
              this_val = in_instance.attributes[field_name.to_s]
              if expected_val.is_a? Array
                array_res = false
                expected_val.each do |e|
                  array_res ||= (this_val == e)
                end
                res &&= array_res
              else
                res &&= this_val == expected_val
              end
              if expected_val == 'return_value' || expected_val.is_a?(Array) && expected_val.include?('return_value')
                @this_val = this_val
              elsif expected_val == 'return_result'
                @this_val = in_instance
              end
            end

          end
        elsif table == :user
          if field_name == :role_name
            user = @current_instance.master.current_user
            role_names = user.user_roles.active.pluck(:role_name)
            @this_val = role_names if expected_val == 'return_value' || expected_val.is_a?(Array) && expected_val.include?('return_value')
            expected_val = [expected_val] unless expected_val.is_a? Array
            role_res = false
            expected_val.each do |e|
              role_res ||= role_names.include? e
            end
            res &&= role_res
          else
            res = false
          end
        end
      end
      res
    end

    # Generate query conditions and a list of join tables based on a conditional configuration,
    # such as
    # creatable_if:
    #  all:
    #    <creatable conditions>
    #
    def calc_base_query condition_type

      # join_tables = @condition_config.keys.map(&:to_sym) - SelectionTypes
      join_tables = []
      @condition_values = {}
      @extra_conditions = []
      @non_query_conditions = {}
      @sub_conditions = {}

      @condition_config.each do |c_table, t_conds|
        join_table_name = c_table.to_sym
        table_name = ModelReference.record_type_to_table_name(c_table).to_sym

        if is_selection_type(table_name)
          # Does this actually do anything?
          @sub_conditions[table_name] ||= {}
          @sub_conditions[table_name] = t_conds
        else

          t_conds.each do |field_name, val|

            non_query_condition = table_name.in?([:this, :user, :parent, :referring_record])
            if field_name == :return_constant
              non_query_condition = true
            elsif val.is_a? Hash
              val_item_key = val.first.first

              if is_selection_type(val_item_key)
                val_item_key = :this
                val = {this: val}
              end

              if val_item_key == :this && !val.first.last.is_a?(Hash)
                # non_query_condition = true
                val = @current_instance.attributes[val.first.last]
              elsif val_item_key == :parent && !val.first.last.is_a?(Hash)
                # non_query_condition = true
                val = @current_instance.parent_item.attributes[val.first.last]
              elsif val_item_key == :referring_record && !val.first.last.is_a?(Hash)
                # non_query_condition = true
                val = @current_instance.referring_record && @current_instance.referring_record.attributes[val.first.last]
              elsif val_item_key == :this_references
                if val.first.last.is_a?(Hash)
                  att = val.first.last.first.last
                  to_table_name = val.first.last.first.first
                  val = []
                  model_refs = @current_instance.model_references(active_only: true)
                  model_refs = model_refs.select {|r| r.to_record_type == to_table_name.to_s.singularize.ns_camelize}

                  model_refs.each do |mr|
                    val << mr.to_record.attributes[att]
                  end

                else
                  att = val.first.last
                  # non_query_condition = true
                  val = []

                  mrs = @current_instance.model_references(active_only: true)

                  unless non_join_table_name?(join_table_name)
                    mrs = mrs.select {|r| r.to_record_type == join_table_name.to_s.singularize.ns_camelize}
                  end

                  # Get the specified attribute's value from each of the model references
                  # Generate an array, allowing the conditions to be IN any of these
                  mrs.each do |mr|
                    val << mr.to_record.attributes[att]
                  end
                end
              elsif val_item_key == :parent_references
                if val.first.last.is_a?(Hash)
                  att = val.first.last.first.last
                  to_table_name = val.first.last.first.first
                  val = []
                  raise FphsException.new "No referring record specified when using parent_references" unless @current_instance.referring_record
                  parent_model_refs = @current_instance.referring_record.model_references(active_only: true)
                  parent_model_refs = parent_model_refs.select {|r| r.to_record_type == to_table_name.to_s.singularize.ns_camelize}

                  parent_model_refs.each do |mr|
                    val << mr.to_record.attributes[att]
                  end

                else
                  att = val.first.last
                  # non_query_condition = true
                  val = []

                  # Get the specified attribute's value from each of the parent model references
                  # Generate an array, allowing the conditions to be IN any of these
                  # parent_model = ModelReference.find_where_referenced_from(@current_instance).order(id: :desc).first
                  parent_model_refs = @current_instance.referring_record.model_references(active_only: true)

                  unless non_join_table_name?(join_table_name)
                    parent_model_refs = parent_model_refs.select {|r| r.to_record_type == join_table_name.to_s.singularize.ns_camelize}
                  end

                  parent_model_refs.each do |mr|
                    val << mr.to_record.attributes[att]
                  end
                end
              else
                val.keys.each do |val_key|
                  if non_join_table_name?(val_key)
                    non_query_condition = true
                  else
                    join_tables << val_key unless join_tables.include? val_key
                  end
                end
              end
            end
            unless non_query_condition
              if val.is_a?(Hash) && val[:condition].in?(ValidExtraConditions)

                if @extra_conditions[0].blank?
                  @extra_conditions[0] = ""
                else
                  @extra_conditions[0] += " #{BoolTypeString} "
                end

                vc = ValidExtraConditions.find {|c| c == val[:condition]}
                vv = dynamic_value(val[:value])

                @extra_conditions[0] += "#{table_name}.#{field_name} #{vc} (?)"
                @extra_conditions << vv
              elsif val.is_a?(Hash) && val[:condition].in?(ValidExtraConditionsArrays)
                  veca_extra_args = ''
                  if @extra_conditions[0].blank?
                    @extra_conditions[0] = ""
                  else
                    @extra_conditions[0] += " #{BoolTypeString} "
                  end

                  vc = ValidExtraConditionsArrays.find {|c| c == val[:condition]}
                  vv = dynamic_value(val[:value])

                  negate = (val[:not] ? 'NOT' : '')

                  leftop = '?'
                  if vc == '&&'
                    leftop = "ARRAY[?]"
                    if vv.first.is_a? String
                      leftop += "::varchar[]"
                    end
                  end



                  veca_extra_args = ', 1' if vc.include?('ARRAY_LENGTH')

                  @extra_conditions[0] += "#{negate} (#{leftop} #{vc} (#{table_name}.#{field_name}#{veca_extra_args}))"
                  @extra_conditions << vv
              else
                if val.in?(['return_value', 'return_value_list', 'return_result']) || val.is_a?(Array) && val.include?('return_value')
                  mode = val
                  if val.is_a?(Array) && val.include?('return_value')
                    mode = 'return_value'
                    @condition_values[table_name] ||= {}
                    @condition_values[table_name][field_name] = dynamic_value(val)
                  end
                  @this_val_where = {
                    assoc: c_table.to_sym,
                    field_name: field_name,
                    table_name: ModelReference.record_type_to_ns_table_name(c_table).to_sym,
                    mode: mode
                  }
                else
                  @condition_values[table_name] ||= {}
                  @condition_values[table_name][field_name] = dynamic_value(val)
                end
              end
              join_tables << join_table_name unless join_tables.include? table_name
            else
              @non_query_conditions[table_name] ||= {}
              @non_query_conditions[table_name][field_name] = val
            end
          end
        end
      end
      @join_tables = join_tables = (join_tables - [:this, :parent, :referring_record, :this_references, :parent_references, :user, :master, :condition, :value, :hide_error]).uniq

      if [:all, :not_all].include? condition_type
        @base_query = @current_scope.joins(join_tables)
      else
        @base_query = @current_scope.includes(join_tables)
      end
    end

    # Create a dynamic value if the condition's value matches certain strings
    def dynamic_value val, type=nil
      FieldDefaults.calculate_default(current_instance, val, type)
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
        if is_selection_type c_type
          ca = ConditionalActions.new({c_type => t_conds}, current_instance, current_scope: @condition_scope, return_failures: return_failures)
          res_a = ca.calc_action_if
          res &&= res_a
          @this_val ||= ca.this_val
          return unless res
        end
      end

      return res
    end



    def calc_complex_validation condition, value
      res = true
      condition.each do |k, opts|

        v = new_validator k, value, options:{k=>opts}
        test_res = v.value_is_valid? value, current_instance
        res &&= test_res
      end

      res
    end

    def new_validator k, value, options: {}
      validator_class(k).new options.merge(attributes: {_attr: value})
    end

    def validator_class k
      Validates.const_get("#{k.to_s.classify}Validator")
    end


end
