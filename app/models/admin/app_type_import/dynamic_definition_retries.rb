# frozen_string_literal: true

class Admin::AppTypeImport
  class DynamicDefinitionRetries
    MAX_RETRY_PASSES = 5
    UNLOOKED_UP_ITEM = Object.new.freeze
    DYNAMIC_DEFINITION_KEYS = Admin::AppTypeImport::DynamicDefinitionKeys

    attr_reader :pass

    def initialize(importer)
      @importer = importer
      @original_skip_fail = importer.skip_fail
    end

    def run
      results = {}
      @first_pass_changed_items = Set.new
      @failed_items = Set.new

      execute_pass(:first) { yield self }
      results = merge_results(results, current_pass_results)
      pending_items = @failed_items | @first_pass_changed_items
      pending_failed_items = @failed_items.dup
      retry_passes = 0

      while pending_items.any? && retry_passes < MAX_RETRY_PASSES
        execute_pass(:retry, candidates: pending_items, failed_items: pending_failed_items) { yield self }
        results = merge_results(results, current_pass_results)
        next_pending_items = @failed_items | @incomplete_items
        retry_passes += 1

        break if next_pending_items.empty? || (pending_items - next_pending_items).empty?

        pending_items = next_pending_items
        pending_failed_items = @failed_items.dup
      end

      if @failed_items.any?
        failed_items = @failed_items.dup
        execute_pass(:final, candidates: failed_items, failed_items:) { yield self }
        results = merge_results(results, current_pass_results)
      end

      publish_results(results)
    ensure
      @importer.skip_fail = @original_skip_fail
      @pass = nil
    end

    def process?(item_key, config_item, lookup_existing_with_fields:, app_type_item: UNLOOKED_UP_ITEM)
      return true if pass == :first

      identity = item_identity(item_key, config_item, lookup_existing_with_fields)
      return false unless @retry_candidates.include?(identity)
      return true if @retry_failed_items.include?(identity)
      return true if app_type_item.equal?(UNLOOKED_UP_ITEM)
      return false if app_type_item.blank?

      @importer.dyn_def_db_not_defined(app_type_item, include_reference_views: include_reference_views?)
    end

    def with_item(&action)
      return action.call unless %i[first retry].include?(pass)

      @importer.dyn_cname.transaction(requires_new: true, &action)
    end

    def record(item_key, config_item, lookup_existing_with_fields:, changed: false, failed: false, app_type_item: nil)
      identity = item_identity(item_key, config_item, lookup_existing_with_fields)
      if pass == :first
        @failed_items << identity if failed
        @first_pass_changed_items << identity if changed
      elsif pass == :retry
        @failed_items << identity if failed
        if app_type_item.present? &&
           @importer.dyn_def_db_not_defined(app_type_item, include_reference_views: include_reference_views?)
          @incomplete_items << identity
        end
      end
    end

    def skip_fail
      pass == :final ? @original_skip_fail : true
    end

    def include_reference_views?
      %i[retry final].include?(pass)
    end

    private

    def execute_pass(current_pass, candidates: nil, failed_items: nil)
      @pass = current_pass
      @retry_candidates = candidates || Set.new
      @retry_failed_items = failed_items || Set.new
      @failed_items = Set.new
      @incomplete_items = Set.new
      @importer.skip_fail = skip_fail
      clear_failures unless current_pass == :first
      yield
    end

    def item_identity(item_key, config_item, lookup_existing_with_fields)
      values = lookup_existing_with_fields.map do |field|
        field = field.to_s
        config_item.key?(field) ? config_item[field] : config_item[field.to_sym]
      end
      [item_key.to_s, *values]
    end

    def current_pass_results
      @importer.import_results.slice(*DYNAMIC_DEFINITION_KEYS)
    end

    def clear_failures
      DYNAMIC_DEFINITION_KEYS.each { |key| @importer.import_failures.delete(key) }
    end

    def merge_results(results, pass_results)
      DYNAMIC_DEFINITION_KEYS.each do |key|
        next unless results.key?(key) || pass_results.key?(key)

        entries = results.fetch(key, []) + pass_results.fetch(key, [])
        results[key] = merge_result_entries(entries)
      end
      results
    end

    def merge_result_entries(entries)
      merged = []
      indexes_by_id = {}
      entries.each do |entry|
        id = result_id(entry)
        if id.present? && indexes_by_id.key?(id)
          merged[indexes_by_id[id]] = entry
        else
          indexes_by_id[id] = merged.length if id.present?
          merged << entry
        end
      end
      merged
    end

    def result_id(entry)
      return entry.id if entry.respond_to?(:id)

      entry['id'] || entry[:id] if entry.is_a?(Hash)
    end

    def publish_results(results)
      DYNAMIC_DEFINITION_KEYS.each do |key|
        @importer.import_results[key] = results[key] if results.key?(key)
      end
    end
  end
end
