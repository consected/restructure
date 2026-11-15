# frozen_string_literal: true

class ActivityLog
  module Perspectives
    # Execute a single named perspective for an activity log panel, returning an
    # ActiveRecord::Relation scoped to the caller's master record.
    #
    # Supported backends (mutually exclusive — first match wins):
    #   :report                  — runs a named Report, optionally with {{table_name}} substitution
    #   :where                   — direct AR conditions hash, column-name whitelisted
    #   :conditional_calculation — runs a ConditionalActions calculation using return_all_results
    #
    # Additional modifiers applied on top of the backend result:
    #   :order    — { column: "asc"|"desc" }, whitelisted against class columns
    #   :limit    — integer max records
    #
    # Usage:
    #   relation = ActivityLog::Perspectives::Runner.new(
    #     config, ActivityLog::CaseReview, current_user, master: @master
    #   ).run
    class Runner
      # Allowed ORDER directions
      VALID_DIRECTIONS = %w[asc desc].freeze

      # @param config [Hash] a single perspective definition hash from page_layout
      #   view_options.perspectives[<resource_name>][idx]
      # @param al_class [Class] the activity log implementation class
      # @param current_user [User]
      # @param master [Master]
      def initialize(config, al_class, current_user, master:)
        @config = config.with_indifferent_access
        @al_class = al_class
        @current_user = current_user
        @master = master
      end

      # Run the perspective and return an ActiveRecord::Relation.
      # Returns nil only when a backend legitimately produces no results (e.g. a
      # conditional_calculation where no records match). Raises on configuration
      # errors so the caller can surface the problem rather than silently bypassing
      # the filter and showing unfiltered records.
      # @return [ActiveRecord::Relation, nil]
      def run
        Rails.logger.debug { "ActivityLog::Perspectives::Runner#run – al_class=#{@al_class}, master=#{@master&.id}, config=#{@config.to_h}" }
        base = run_backend
        base = apply_order(base)
        base = apply_limit(base)
        Rails.logger.debug { "ActivityLog::Perspectives::Runner#run – result SQL: #{base&.to_sql}" }
        base
      end

      private

      def run_backend
        if @config[:report].present?
          run_report_backend
        elsif @config[:where].present?
          run_where_backend
        elsif @config[:conditional_calculation].present?
          run_conditional_calculation_backend
        else
          # No backend — return all records for this master (acts as an "all" perspective reset)
          @al_class.where(master_id: @master.id)
        end
      end

      # Run a Report-based perspective.
      # The report SQL may use {{table_name}}/{{schema_name}} substitutions.
      def run_report_backend
        resource_name = @config.dig(:report, :resource_name)
        Rails.logger.debug { "ActivityLog::Perspectives::Runner#run_report_backend – resource_name=#{resource_name.inspect}" }
        report = Report.find_by_id_or_resource_name(resource_name)
        raise FphsException, "Perspective report not found: #{resource_name}" unless report

        Rails.logger.debug { "ActivityLog::Perspectives::Runner#run_report_backend – report found id=#{report.id} (#{report.alt_resource_name})" }

        # Perspectives are configured by admins in page layouts that users already have access to,
        # and results are always scoped to @master.id via the final where() clause below.
        # We therefore skip per-report UAC and require only that the report is active (already
        # ensured by find_by_id_or_resource_name which scopes to Report.active).

        report.current_user = @current_user
        runner = report.runner

        if report.uses_table_subs?
          schema_name = Admin::MigrationGenerator.table_schema_hash[@al_class.table_name]
          runner.data_reference.init(
            table_name: @al_class.table_name,
            schema_name: schema_name
          )
        end

        # Only inject master_id into the report params when the report's search_attrs
        # explicitly defines it. Reports::Runner#search_attrs_prep slices the params hash
        # down to only the keys present in search_attrs, so injecting master_id when it
        # is not declared there would cause sanitize_sql_for_conditions to raise
        # PreparedStatementInvalid (unrecognised named bind variable :master_id). The
        # final scope below always restricts results to @master regardless, so the
        # SQL-level filter is an optimisation only.
        report_attr_keys = report.search_attributes.symbolize_keys.keys
        master_id_param  = report_attr_keys.include?(:master_id) ? { master_id: @master.id } : {}
        defaults = (@config.dig(:report, :defaults) || {}).merge(master_id_param)
        Rails.logger.debug { "ActivityLog::Perspectives::Runner#run_report_backend – running report with defaults=#{defaults.inspect}" }
        raw_results = runner.run(defaults)

        # Extract IDs from raw PG result set and scope back through the correct
        # al_class + master_id so that records from other resources or masters
        # that happen to share an ID cannot leak into the result.
        ids = raw_results.map { |r| r['id'].to_i }.compact
        Rails.logger.debug { "ActivityLog::Perspectives::Runner#run_report_backend – report returned #{ids.length} ids: #{ids.first(10).inspect}" }
        # Remember the ordered IDs so apply_order can preserve SQL row order when no
        # explicit order: is configured on this perspective.
        @report_ordered_ids = ids
        @al_class.where(master_id: @master.id, id: ids)
      end

      # Run a simple where-hash perspective.
      # Column names are validated against the class's actual columns to prevent injection.
      def run_where_backend
        @al_class.where(master_id: @master.id).where(sanitized_where_conditions)
      end

      # Run a ConditionalActions-based perspective using return_all_results.
      #
      # The config value is the inner CalcActions condition hash.  It should target the
      # activity log table using simple field conditions plus a `return: return_all_results`
      # directive at the table level.  Example:
      #
      #   conditional_calculation:
      #     activity_log__case_reviews:
      #       status: active
      #       return: return_all_results
      #
      # `no_masters: {}` is injected automatically so ConditionalActions queries the activity
      # log class directly rather than joining through the masters table.  This is required
      # for return_all_results to produce activity log record IDs rather than master IDs.
      # If `no_masters` is already present in the supplied config it is left unchanged.
      #
      # Returns nil if no value is set by the calculation (e.g. no results match, or
      # return_all_results is not used in the config).
      def run_conditional_calculation_backend
        # Deep-dup and coerce to indifferent access before modifying
        calc_config = @config[:conditional_calculation].deep_dup.with_indifferent_access

        # Perspectives query the activity log class directly (not joined through masters).
        # Inject no_masters: {} so CalcActions uses the AL class as the base scope;
        # without this, return_all_results would pluck master IDs instead of AL record IDs.
        calc_config[:no_masters] ||= {}

        ca = ConditionalActions.new(calc_config, context_instance)
        ca.get_this_val

        return nil unless ca.this_val_set?

        result = ca.this_val
        return nil unless result.present?

        # Re-scope through al_class + master_id to prevent cross-resource or cross-master
        # leakage regardless of what the calculation returns.
        ids = result.is_a?(ActiveRecord::Relation) ? result.pluck(:id) : Array(result).map(&:id)
        @al_class.where(master_id: @master.id, id: ids)
      end

      # Validate each key in the where config against the class's column names.
      # String values may contain {{field_defaults}} substitutions which are resolved
      # against the current user/master context before the condition is applied.
      # Returns a clean hash safe to pass to AR's where().
      # Raises FphsException on unknown columns or unresolved template references so
      # admin misconfiguration is surfaced immediately rather than silently ignored.
      def sanitized_where_conditions
        allowed_columns = @al_class.column_names.map(&:to_s)
        @config[:where].each_with_object({}) do |(k, v), h|
          col = k.to_s
          unless allowed_columns.include?(col)
            raise FphsException,
                  "Perspectives::Runner – where: key #{col.inspect} is not a valid column on #{@al_class}"
          end

          if v.is_a?(String)
            result = FieldDefaults.calculate_default(context_instance, v, ignore_missing: true)
            if result.blank? && v.include?('{{')
              raise FphsException,
                    "Perspectives::Runner – where: value #{v.inspect} for column #{col.inspect} resolved to blank; " \
                    'check field reference in template'
            end

            h[col] = result
          else
            h[col] = v
          end
        end
      end

      # A lightweight unsaved instance of the activity log class used as the substitution
      # context for FieldDefaults and ConditionalActions.  Memoized so all backends share
      # the same object within a single #run call.
      def context_instance
        @context_instance ||= begin
          inst = @al_class.new(master_id: @master.id)
          inst.current_user = @current_user
          inst
        end
      end

      # Apply ordering to the relation.
      #
      # Priority:
      #   1. Explicit `order:` in perspective config — always wins (column-name whitelisted).
      #   2. Report backend with no explicit order — preserve the SQL row order returned by
      #      the report using array_position so the caller's ORDER BY is honoured.
      #   3. All other backends with no explicit order — order chronologically by
      #      action_when_attribute DESC, id DESC (mirrors the Master has_many scope).
      def apply_order(relation)
        return relation if relation.nil?

        if @config[:order].present?
          # Explicit order: always wins. Raise on any invalid column or direction so the
          # admin knows the config is wrong rather than silently falling back to default order.
          allowed_columns = @al_class.column_names.map(&:to_s)
          order_clauses = @config[:order].each_with_object({}) do |(col, dir), h|
            col_s = col.to_s
            dir_s = dir.to_s.downcase
            unless allowed_columns.include?(col_s)
              raise FphsException,
                    "Perspectives::Runner – order: column #{col_s.inspect} is not a valid column on #{@al_class}"
            end
            unless VALID_DIRECTIONS.include?(dir_s)
              raise FphsException,
                    "Perspectives::Runner – order: direction #{dir.inspect} for column #{col_s.inspect} is not valid; use 'asc' or 'desc'"
            end

            h[col_s] = dir_s
          end
          return relation.reorder(order_clauses)
        end

        if @report_ordered_ids
          # Report backend: preserve the SQL row order using array_position.
          # Skip if no results (WHERE id IN () already returns nothing).
          return relation unless @report_ordered_ids.any?

          safe_sql = ActiveRecord::Base.sanitize_sql_array([
            "array_position(ARRAY[?]::integer[], #{@al_class.quoted_table_name}.id)",
            @report_ordered_ids.map(&:to_i)
          ])
          
          return relation.reorder(Arel.sql(safe_sql))
        end

        # Non-report backends: apply action_when_attribute DESC, id DESC.
        # This mirrors the ordering used on the Master has_many association scope.
        # Use created_at when action_when_attribute is :alt_order (a pseudo-attribute).
        awa = @al_class.action_when_attribute
        awa = :created_at if awa == :alt_order
        relation.reorder(awa => :desc, id: :desc)
      end

      # Apply a LIMIT from config.
      # Raises FphsException when a limit: value is present but not a positive integer.
      def apply_limit(relation)
        return relation unless @config[:limit].present?

        limit = @config[:limit].to_i
        unless limit.positive?
          raise FphsException,
                "Perspectives::Runner – limit: #{@config[:limit].inspect} is not a positive integer"
        end

        relation.limit(limit)
      end
    end
  end
end
