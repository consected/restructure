# frozen_string_literal: true

module CalcActions
  # Resolves the protocol_name, sub_process_name and protocol_event_name keys of tracker_history conditions to the
  # protocol_id, sub_process_id and protocol_event_id values used in the query.
  #
  # Each name is looked up within its parent, in order: a protocol, then a sub process within that protocol, then a
  # protocol event within that sub process. This means the same names may be used under different protocols.
  # Names must match exactly one active record. Otherwise a FphsException is raised, so that a mistyped name cannot
  # silently change the result of a condition (for example under not_all).
  class TrackerHistoryNames
    LEVELS = {
      protocol: { model: Classification::Protocol, parent: nil, parent_column: nil },
      sub_process: { model: Classification::SubProcess, parent: :protocol, parent_column: :protocol_id },
      protocol_event: { model: Classification::ProtocolEvent, parent: :sub_process, parent_column: :sub_process_id }
    }.freeze

    NAME_KEYS = LEVELS.keys.map { |level| :"#{level}_name" }.freeze
    TABLES = %i[tracker_history tracker_histories].freeze

    # @param conditions [Hash] the field conditions for a tracker_history table
    # @yieldparam value [Object] a configured value, which may be a substitution, to be evaluated
    # @yieldreturn [Object] the evaluated value
    def initialize(conditions, &evaluator)
      @conditions = conditions
      @evaluator = evaluator
      @resolved_ids = {}
    end

    # @return [Hash] the conditions with each name key replaced by its id key, or unchanged if there are no name keys
    def resolve
      return @conditions unless NAME_KEYS.any? { |key| @conditions.key?(key) }

      resolved = @conditions.except(*NAME_KEYS)
      LEVELS.each do |level, options|
        check_id_and_name_not_both(level)
        next unless @conditions.key?(:"#{level}_name")

        resolved[:"#{level}_id"] = lookup(level, options)
      end
      resolved
    end

    private

    def check_id_and_name_not_both(level)
      return unless @conditions.key?(:"#{level}_id") && @conditions.key?(:"#{level}_name")

      raise FphsException, "#{level}_id and #{level}_name cannot both be given in tracker_history conditions"
    end

    def lookup(level, options)
      name_key = :"#{level}_name"
      name = name_value(name_key)
      parent_id = parent_id_for(level, options[:parent])

      matches = scope_for(options, parent_id).where(name:).pluck(:id)
      raise FphsException, not_found_message(name_key, name, options, parent_id) if matches.empty?
      raise FphsException, ambiguous_message(name_key, name) if matches.many?

      @resolved_ids[level] = matches.first
    end

    def name_value(name_key)
      name = @evaluator.call(@conditions[name_key])
      name = name.to_s if name.is_a?(Numeric)
      raise FphsException, "#{name_key} must not be blank in tracker_history conditions" if name.blank?
      raise FphsException, "#{name_key} must be a single name in tracker_history conditions" unless name.is_a?(String)

      name
    end

    # A child name needs its parent, given either by name (already resolved) or by id
    def parent_id_for(level, parent)
      return unless parent

      parent_id_key = :"#{parent}_id"
      parent_name_key = :"#{parent}_name"
      unless @conditions.key?(parent_id_key) || @conditions.key?(parent_name_key)
        raise FphsException,
              "#{level}_name requires #{parent_id_key} or #{parent_name_key} in tracker_history conditions"
      end

      return @resolved_ids[parent] if @conditions.key?(parent_name_key)

      @evaluator.call(@conditions[parent_id_key])
    end

    def scope_for(options, parent_id)
      scope = options[:model].active
      return scope unless options[:parent]

      scope.where(options[:parent_column] => parent_id)
    end

    def not_found_message(name_key, name, options, parent_id)
      label = name_key.to_s.delete_suffix('_name').tr('_', ' ')
      within = options[:parent] ? " within #{options[:parent]}_id #{parent_id}" : ''
      "No active #{label} matches #{name_key} '#{name}'#{within} in tracker_history conditions"
    end

    def ambiguous_message(name_key, name)
      "#{name_key} '#{name}' matches more than one active record in tracker_history conditions"
    end
  end
end
