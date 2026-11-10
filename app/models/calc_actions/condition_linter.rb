# frozen_string_literal: true

module CalcActions
  # Static checks for conditional calculation configurations: the CalcActions condition hashes evaluated by
  # ConditionalActions. The checks follow the structure accepted at runtime by CalcActions::Calculate and
  # CalcActions::NonQueryCondition, using their vocabulary constants as the schema.
  #
  # Problems are reported as warnings in the form { path:, message: }. Linting never prevents a save.
  #
  # Modes:
  #   :condition - a condition evaluated as true or false (creatable_if, if: clauses and so on).
  #                The top level must be selection types, always / never or shortcuts.
  #   :value     - a configuration returning values (get_this_val), such as first: and with: values,
  #                lookup: sub-queries and perspective conditional_calculation. The top level is a block
  #                of record sources, optionally with selection types.
  class ConditionLinter
    SELECTION_TYPES = CalcActions::Common::SelectionTypes
    RETURN_TYPES = CalcActions::Calculate::ReturnTypes
    NON_JOIN_KEYS = CalcActions::Calculate::NonJoinTableNames
    NON_QUERY_SOURCES = CalcActions::NonQueryCondition::NonQueryTableNames
    VALID_CALCULATE_FUNCTIONS = CalcActions::NonQueryCondition::ValidCalculateFunctions

    # Keys that appear within a block alongside record sources
    BLOCK_KEYS = %i[invalid_error_message has_created_activity has_not_created_activity].freeze
    TOP_LEVEL_KEYS = (BLOCK_KEYS + %i[always never]).freeze

    # Reserved words that are never record sources, although they may appear in a condition
    RESERVED_KEYS = (NON_JOIN_KEYS - NON_QUERY_SOURCES - %i[masters users definition_resources]).freeze

    REFERENCE_KEYS = %i[this parent embedded_item referring_record top_referring_record reference user
                        this_references parent_references parent_or_this_references ids_referencing lookup].freeze
    RETURN_FLAGS = %i[return_value return_value_list return_result return_all_results].freeze
    FIELD_CONDITION_KEYS = (%i[condition value not element hide_error invalid_error_message] + RETURN_FLAGS).freeze
    SPECIAL_FIELDS = %i[return_constant exists role_name].freeze
    # Maximum edit distance from a return keyword for a string value to be reported as a probable typo
    RETURN_TYPO_DISTANCE = 2

    # Operators evaluated in memory against this record (see NonQueryCondition#eval_simple_condition)
    IN_MEMORY_OPERATORS = (CalcActions::NonQueryCondition::SimpleConditions +
                           CalcActions::Common::UnaryConditions +
                           (CalcActions::Common::ValidExtraConditionsArrays - ['@>', '<@'])).freeze
    # Operators compiled into database queries (see Calculate#handle_condition_tag)
    DATABASE_OPERATORS = (CalcActions::Common::ValidExtraConditions +
                          CalcActions::Common::ValidExtraConditionsArrays).freeze

    # Describes the record source a field belongs to.
    #   kind: :in_memory - this record, compared in memory
    #         :non_query - a special record source resolved at runtime (user, parent, ...)
    #         :table     - a table joined to masters, a resource or users
    Source = Struct.new(:table, :klass, :kind, keyword_init: true) do
      def in_memory? = kind == :in_memory
    end

    # Context inherited from enclosing blocks
    #   any_block - directly within an any or not_any block
    #   no_masters - the query is based on a resource rather than masters
    Context = Struct.new(:any_block, :no_masters, keyword_init: true) do
      def with(**changes) = self.class.new(**to_h, **changes)
    end

    # @param condition [Hash, nil] the configuration to lint
    # @param path [String, Array] location of the configuration, as a dotted String or as path keys. It is the
    #   prefix of the path keys of each notice
    # @param model_class [Class, nil] the class of this record, used to check this: fields when known
    # @param mode [Symbol] :condition or :value
    # @param implied_no_masters [Boolean] true when no_masters: {} was added to the top-level block by a perspective,
    #   so that its messages describe the perspective rather than refer to no_masters
    def initialize(condition:, path:, model_class:, mode: :condition, implied_no_masters: false)
      raise ArgumentError, "unknown mode #{mode.inspect}" unless %i[condition value].include?(mode.to_sym)

      @condition = condition.is_a?(Hash) ? condition.deep_symbolize_keys : condition
      @path_keys = self.class.path_keys(path)
      @model_class = model_class
      @mode = mode.to_sym
      @implied_no_masters = implied_no_masters
      @notices = []
    end

    # Converts a dotted location, such as options.default.showable_if, into path keys
    # @return [Array<String, Integer>]
    def self.path_keys(path)
      return path.map { |key| key.is_a?(Integer) ? key : key.to_s } if path.is_a?(Array)

      path.to_s.empty? ? [] : path.to_s.split('.')
    end

    # The dotted location of path keys, with list indexes in brackets, such as default.set_variables[0].if
    # @return [String]
    def self.dotted_path(keys)
      keys.inject(+'') do |dotted, key|
        if key.is_a?(Integer)
          "#{dotted}[#{key}]"
        else
          dotted.empty? ? key.to_s : "#{dotted}.#{key}"
        end
      end
    end

    # @return [Array<Hash>] notices of the form { path: String, path_keys: Array, message: String }, where path
    #   is the dotted form of path_keys. Messages state only the problem, and the path keys locate it.
    def lint
      @notices = []
      if @mode == :value
        lint_value_config(@condition, @path_keys, base_context)
      else
        lint_condition(@condition, @path_keys)
      end
      @notices
    end

    private

    def base_context
      Context.new(any_block: false, no_masters: false)
    end

    def lint_condition(conf, path)
      return if conf.nil?
      return add(path, 'a condition must be a Hash of selection types') unless conf.is_a?(Hash)

      conf.each do |key, val|
        if selection_key?(key)
          lint_selection(key, val, join(path, key), base_context)
        elsif !key.in?(TOP_LEVEL_KEYS)
          add(join(path, key), "unrecognized top-level key '#{key}' - use all, any, not_all or not_any " \
                               '(optionally with a suffix), always, never, has_created_activity or ' \
                               'has_not_created_activity')
        end
      end
    end

    def lint_value_config(conf, path, ctx)
      return unless conf.is_a?(Hash)
      return if conf.keys == [:object]

      lint_block(conf, path, ctx)
    end

    # A block holds record sources, selection types and shortcuts
    def lint_block(block, path, ctx)
      if block.key?(:no_masters)
        check_no_masters_base(block, path)
        ctx = ctx.with(no_masters: true)
      end

      block.each do |key, val|
        next if key.in?(BLOCK_KEYS) || key == :no_masters

        if selection_key?(key)
          lint_selection(key, val, join(path, key), ctx)
        else
          lint_source(key, val, join(path, key), ctx)
        end
      end
    end

    # A selection type holds a block, or a list of blocks evaluated in turn
    def lint_selection(key, val, path, ctx)
      any_block = selection_base(key).in?(%i[any not_any])
      blocks = val.is_a?(Array) ? val : [val]

      blocks.each_with_index do |block, index|
        block_path = val.is_a?(Array) ? path + [index] : path
        if block.is_a?(Hash)
          lint_block(block, block_path, ctx.with(any_block:))
        else
          add(block_path, "#{key} must be a Hash of record sources, or a list of them")
        end
      end
    end

    # The base table is reported at its own key, which is part of the configuration. A block without a base table
    # is reported at the block, since no_masters: {} may be implied by a perspective rather than written.
    def check_no_masters_base(block, path)
      base = block.keys.find { |key| join_table?(key) }
      return add(path, no_base_message(path)) unless base
      return if base == :definition_resources || resource_for(base)

      add(join(path, base), unknown_base_message(base, implied_no_masters?(path)))
    end

    # no_masters is only implied for the top-level block of a perspective, so only that block is described as implied
    def implied_no_masters?(path)
      @implied_no_masters && path == @path_keys
    end

    def no_base_message(path)
      return 'no_masters: {} needs a table to act as the base of the query' unless implied_no_masters?(path)

      'a perspective conditional_calculation needs a resource, such as an activity log or dynamic model, ' \
        'to act as the base of the query'
    end

    def unknown_base_message(base, implied)
      return "'#{base}' is not a known resource to use as the base of a no_masters: {} query" unless implied

      "'#{base}' is not a known resource. A perspective conditional_calculation must start from an activity log, " \
        'dynamic model or other resource'
    end

    def lint_source(table, fields, path, ctx)
      return add(path, "'#{table}' must be a Hash of field conditions") unless fields.is_a?(Hash)
      return add(path, "'#{table}' is a reserved key and is not a record source") if table.in?(RESERVED_KEYS)

      source = source_for(table, path, ctx)
      return unless source

      fields.each do |field, cond|
        next if field == :invalid_error_message

        field_path = join(path, field)
        if field == :and_latest_matches
          lint_and_latest_matches(cond, field_path, source)
        else
          lint_field(field, cond, field_path, source, ctx)
        end
      end
    end

    def source_for(table, path, ctx)
      case table
      when :this then Source.new(table:, klass: @model_class, kind: :in_memory)
      when :masters then Source.new(table:, klass: Master, kind: :table)
      when :users then Source.new(table:, klass: User, kind: :table)
      when :definition_resources then Source.new(table:, klass: nil, kind: :table)
      when *NON_QUERY_SOURCES then Source.new(table:, klass: (table == :user ? User : nil), kind: :non_query)
      else join_source(table, path, ctx)
      end
    end

    def join_source(table, path, ctx)
      return Source.new(table:, klass: resource_class(table), kind: :table) if ctx.no_masters

      reflection = Master.reflect_on_association(table)
      unless reflection
        add(path, "'#{table}' is not a resource or an association of masters - for a table without a master " \
                  'use no_masters: {}')
        return
      end

      Source.new(table:, klass: reflection_class(reflection), kind: :table)
    end

    def lint_field(field, cond, path, source, ctx)
      return lint_calculate(cond, path, source) if field == :calculate

      check_attribute(field, source.klass, path, source.table) unless pseudo_field?(field)
      lint_field_value(cond, path, source, ctx)
    end

    # The return pseudo-field (return: return_result) and special fields are not attributes of the record
    def pseudo_field?(field)
      field == :return || field.in?(SPECIAL_FIELDS)
    end

    def lint_field_value(cond, path, source, ctx)
      case cond
      when Hash then lint_field_hash(cond, path, source, ctx)
      when String then add(path, unknown_return_message(cond)) if likely_return_typo?(cond)
      end
    end

    # At runtime only the exact return keywords are special, so other strings are literal values.
    # A value within a few edits of a return keyword is most likely a typo of that keyword.
    def likely_return_typo?(value)
      return false if value.in?(RETURN_TYPES)

      RETURN_TYPES.any? { |type| DidYouMean::Levenshtein.distance(value, type) <= RETURN_TYPO_DISTANCE }
    end

    def lint_field_hash(cond, path, source, ctx)
      return if cond.keys == [:object]

      if cond.key?(:condition)
        lint_field_condition(cond, path, source, ctx)
      elsif cond.key?(:element)
        lint_element(cond, path)
      elsif cond.key?(:calculate)
        lint_calculate(cond[:calculate], join(path, :calculate), source)
      elsif cond.key?(:validate)
        lint_validate(cond[:validate], join(path, :validate))
      elsif cond.keys.any? { |key| selection_key?(key) }
        cond.each_key { |key| lint_selection(key, cond[key], path, ctx) if selection_key?(key) }
      elsif (reference = cond.keys.find { |key| key.in?(REFERENCE_KEYS) })
        lint_reference(reference, cond[reference], path)
      else
        lint_value_config(cond, path, ctx)
      end
      lint_return_flags(cond, path)
    end

    def lint_field_condition(cond, path, source, ctx)
      unknown = cond.keys - FIELD_CONDITION_KEYS
      add(path, "unrecognized key(s) #{unknown.join(', ')} alongside condition:") if unknown.any?

      operator = cond[:condition]
      return add(path, 'condition: must be given an operator') if operator.nil?

      check_operator(operator, path, source)
      if allowed_operator?(operator, source) && requires_value?(operator) && !cond.key?(:value)
        add(path, "condition '#{operator}' requires a value: key")
      end
      return unless database_condition_in_any?(operator, source, ctx)

      add(path, "database condition '#{operator}' cannot be used within any or not_any blocks - move it into " \
                'an all or not_all block, or nest an all block within the any')
    end

    def check_operator(operator, path, source)
      return if allowed_operator?(operator, source)

      allowed = allowed_operators(source)
      where = source.in_memory? ? 'in memory on this record' : 'on database tables'
      add(path, "condition '#{operator}' is not supported #{where} - use one of: #{allowed.join(', ')}")
    end

    def allowed_operator?(operator, source)
      operator.in?(allowed_operators(source))
    end

    def allowed_operators(source)
      source.in_memory? ? IN_MEMORY_OPERATORS : DATABASE_OPERATORS
    end

    def requires_value?(operator)
      !operator.in?(CalcActions::Common::UnaryConditions)
    end

    def database_condition_in_any?(operator, source, ctx)
      ctx.any_block && source.kind == :table && operator.in?(DATABASE_OPERATORS)
    end

    def lint_element(cond, path)
      element = cond[:element]
      return if element.is_a?(String) || element.is_a?(Symbol)

      add(join(path, :element), 'element: must be a dot separated String, such as result1.res_value')
    end

    def lint_reference(key, val, path)
      case key
      when :this then check_attribute(val, @model_class, path, 'this') unless val.is_a?(Hash)
      when :user then check_user_value(val, path) unless val.is_a?(Hash)
      when :this_references, :parent_references, :parent_or_this_references then check_reference_value(key, val, path)
      when :ids_referencing then lint_ids_referencing(val, path)
      when :lookup then lint_lookup(val, path)
      end
    end

    def check_user_value(val, path)
      return if val.to_s == 'role_name'

      check_attribute(val, User, path, 'user')
    end

    def check_reference_value(key, val, path)
      return if val.is_a?(String) || val.is_a?(Symbol)
      return if val.is_a?(Hash) && val.size == 1 && single_attribute_value?(val.values.first)

      add(path, "#{key} must name an attribute, or a record type and attribute, " \
                "such as #{key}: { address: rank }")
    end

    def single_attribute_value?(value)
      value.is_a?(String) || value.is_a?(Symbol)
    end

    def lint_ids_referencing(val, path)
      unless val.is_a?(Hash) && val.key?(:target) && val.key?(:from)
        return add(path, 'ids_referencing must provide target: and from:')
      end

      target = val[:target]
      unless target.is_a?(Hash) && target.size == 1
        add(join(path, :target),
            'target: must name one record type with its conditions')
      end

      from = val[:from]
      return add(join(path, :from), 'from: must be a condition hash') unless from.is_a?(Hash)

      lint_value_config(from, join(path, :from), base_context)
      return if returns_requested(from).include?('return_all_results')

      add(join(path, :from), 'from: must request return: return_all_results')
    end

    def lint_lookup(val, path)
      return add(path, 'lookup: must be a condition hash') unless val.is_a?(Hash)

      lint_value_config(val, path, base_context)
      modes = returns_requested(val)
      return add(path, 'lookup must request return_value or return_value_list') if modes.empty?

      unsupported = modes - %w[return_value return_value_list]
      return if unsupported.empty?

      add(path, "lookup supports only return_value or return_value_list (found #{unsupported.join(', ')})")
    end

    # Return flags are only applied to a condition, and at most one may be given
    def lint_return_flags(cond, path)
      flags = RETURN_FLAGS.select { |flag| cond[flag] }
      if flags.length > 1
        add(path, "condition: may specify at most one return flag (found #{flags.join(', ')})")
      elsif flags.any? && !cond.key?(:condition)
        add(path, "#{flags.first} is only supported alongside a condition: key")
      end
    end

    def lint_calculate(calc, path, source)
      return add(path, 'calculate: must be a Hash naming one function') unless calc.is_a?(Hash) && calc.size == 1

      function, args = calc.first
      unless function.in?(VALID_CALCULATE_FUNCTIONS)
        supported = VALID_CALCULATE_FUNCTIONS.join(', ')
        return add(path, "calculate function '#{function}' is not supported - use one of: #{supported}")
      end

      attributes = args[:attributes] if args.is_a?(Hash)
      return add(join(path, function), "#{function} requires an attributes: list") unless attributes.is_a?(Array)

      return unless source.in_memory?

      attributes.each { |attribute| check_attribute(attribute, source.klass, join(path, function), source.table) }
    end

    def lint_validate(validate, path)
      return add(path, 'validate: must be a Hash of validator names and their options') unless validate.is_a?(Hash)

      validate.each_key do |name|
        add(join(path, name), "unknown validator '#{name}'") unless validator?(name)
      end
    end

    def lint_and_latest_matches(cond, path, source)
      return add(path, 'and_latest_matches must be a Hash of field conditions') unless cond.is_a?(Hash)

      cond.each_key { |field| check_attribute(field, source.klass, join(path, field), source.table) }
    end

    # Check a field name, or a this: value, against the attributes of a known class.
    # Accessors (such as save_trigger_results) and previous_value_of_ prefixes are accepted.
    def check_attribute(name, klass, path, label)
      return unless klass.respond_to?(:attribute_names)

      base = name.to_s.delete_prefix('previous_value_of_')
      return if klass.attribute_names.include?(base) || klass.method_defined?(base)

      add(path, "'#{name}' is not a field of #{klass.name} (#{label})")
    end

    # All return keywords requested within a configuration, including return flags such as return_value: true
    def returns_requested(node)
      case node
      when Hash
        node.flat_map do |key, value|
          flagged = key.in?(RETURN_FLAGS) && value ? [key.to_s] : []
          flagged + returns_requested(value)
        end
      when Array then node.flat_map { |item| returns_requested(item) }
      when String then node.in?(RETURN_TYPES) ? [node] : []
      else []
      end
    end

    def unknown_return_message(value)
      "unrecognized return keyword '#{value}' - use one of: #{RETURN_TYPES.join(', ')}"
    end

    def validator?(name)
      Validates.const_get("#{name.to_s.classify}Validator")
      true
    rescue NameError
      false
    end

    def resource_for(table)
      Resources::Models.find_by(resource_name: table) || Resources::Models.find_by(table_name: table.to_s)
    end

    def resource_class(table)
      resource = resource_for(table)
      resource && resource[:class_name]&.safe_constantize
    end

    def reflection_class(reflection)
      reflection.klass
    rescue StandardError
      nil
    end

    def join_table?(key)
      !selection_key?(key) && !key.in?(NON_JOIN_KEYS) && !key.in?(%i[no_masters masters invalid_error_message])
    end

    def selection_key?(key)
      (key.is_a?(Symbol) || key.is_a?(String)) && !selection_base(key).nil?
    end

    # Selection types may carry a suffix, such as all_2 or not_any_cancelled
    def selection_base(key)
      SELECTION_TYPES.find { |selection| key.to_s.start_with?(selection.to_s) }
    end

    def join(path, key)
      path + [key.is_a?(Integer) ? key : key.to_s]
    end

    def add(path, message)
      @notices << { path: self.class.dotted_path(path), path_keys: path, message: }
    end
  end
end
