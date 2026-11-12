# frozen_string_literal: true

module Dynamic
  # Works out which records and live definitions the freshness of rendered template config
  # (template_config, index and show responses) depends on, so the live definitions can be
  # refreshed and the tokens used in cache keys calculated from them.
  class TemplateConfigFreshness
    # Refresh the live definition of one representative record per type, and of the target
    # classes of its model references, so their current version tokens are up to date.
    # Each distinct definition is refreshed once.
    # @param records [Array<ActiveRecord::Base>]
    def self.refresh_live_definitions(records)
      representative_records = Array(records).compact.uniq do |record|
        [record.class.name, record.try(:option_type) || record.try(:extra_log_type)]
      end
      definitions = representative_records.filter_map do |record|
        record.current_definition if record.respond_to?(:current_definition)
      end

      reference_types = representative_records.flat_map do |record|
        next [] unless record.respond_to?(:model_references)

        Array(record.model_references).filter_map(&:to_record_type)
      end
      reference_types.uniq.each do |reference_type|
        reference_class = ModelReference.to_record_class_for_type(reference_type)
        definitions << reference_class.definition if reference_class.respond_to?(:definition)
      end

      definitions.compact.uniq { |definition| [definition.class.name, definition.id] }
                 .each(&:refresh_current_def_version!)
    end

    # @param root_records [Array<ActiveRecord::Base>] the records the config is requested for
    def initialize(root_records)
      @root_records = Array(root_records).compact
    end

    # One representative root per definition version, plus the embedded item and referenced
    # records of those roots, sorted by class name and id.
    # @return [Array<ActiveRecord::Base>]
    def records
      @records ||= begin
        representative_roots = @root_records.uniq do |record|
          [record.class.name, record.try(:option_type) || record.try(:extra_log_type), record.try(:def_version)]
        end
        related_records = representative_roots.flat_map { |record| related_records_for(record) }

        (representative_roots + related_records)
          .uniq { |record| [record.class.name, record.id] }
          .sort_by { |record| [record.class.name, record.id.to_i] }
      end
    end

    def refresh!
      self.class.refresh_live_definitions(records)
    end

    # Tokens that change when any record, or the live definition of any record, changes.
    # @param include_activity_item_types [Boolean] also track activity log definitions sharing
    #   the item types of the records, since their config is rendered together
    # @return [Array]
    def tokens(include_activity_item_types: false)
      [record_tokens, definition_tokens, include_activity_item_types ? activity_item_type_tokens : []]
    end

    private

    def related_records_for(record)
      related = []
      embedded_item = record.embedded_item if record.respond_to?(:embedded_item)
      related << embedded_item if embedded_item
      related.concat(Array(record.model_references).filter_map(&:to_record)) if record.respond_to?(:model_references)
      related
    end

    def record_tokens
      records.map do |record|
        version_token = record.vdef_version if record.respond_to?(:vdef_version)
        [record.class.name, record.id, record.updated_at&.to_f, version_token, record.try(:extra_log_type)]
      end
    end

    def definition_tokens
      definitions = records.filter_map do |record|
        record.current_definition if record.respond_to?(:current_definition)
      end
      definitions.map { |definition| Dynamic::TemplateVersionTokens.definition_token(definition) }.uniq
    end

    def activity_item_type_tokens
      item_types = records.filter_map { |record| record.item_type if record.respond_to?(:item_type) }.uniq
      item_types.map { |item_type| Dynamic::TemplateVersionTokens.activity_log_item_type_token(item_type) }
    end
  end
end
