# frozen_string_literal: true

module Dynamic
  # Reports active dynamic definitions (external identifiers, dynamic models and activity logs) that
  # could not be loaded, grouped by cause. It only inspects state that already exists, so it is cheap
  # enough to build on each admin page load. It reports nothing until AppControl has completed a
  # define_models run, because earlier state is expected to be incomplete.
  #
  # External identifiers don't parse their options during generation, so they only appear in the
  # option categories once something has parsed them.
  class DefinitionLoadIssues
    CATEGORY_LABELS = {
      table_or_view_not_found: 'table or view not found',
      failed_to_create: 'failure creating definition',
      options_parse_exception: 'exception parsing options',
      unresolved_references: 'references to definitions not available on this server'
    }.freeze

    MaxDetailLength = 200

    def self.definition_classes
      [ExternalIdentifier, DynamicModel, ActivityLog]
    end

    # True once the definitions are fully set up: a run has completed and nothing is changing them
    def self.reportable?
      AppControl.define_models_completed_since_unload? &&
        !AppControl.defining_models? &&
        !Admin::AppTypeImport.import_in_progress?
    end

    # @return [Hash{Symbol => Array<Hash>}] non-empty categories only, in the order of CATEGORY_LABELS.
    #   Each item has :definition_class, :id, :resource_name, :admin_path and :detail
    def self.grouped
      return {} unless reportable?

      issues = CATEGORY_LABELS.keys.index_with { [] }
      definition_classes.each { |definition_class| collect(issues, definition_class) }
      issues.reject { |_category, items| items.empty? }
    end

    # One line per non-empty category, for Admin::ServerInfo#configuration_failed_reason.
    # Lines are HTML safe so the admin alerts can link each definition to its admin edit page; all text is escaped.
    # @return [Array<ActiveSupport::SafeBuffer>]
    def self.messages
      grouped.map do |category, items|
        helpers.safe_join(
          ["Dynamic definitions not loaded - #{CATEGORY_LABELS[category]} (#{items.length}): ",
           helpers.safe_join(items.map { |item| describe(category, item) }, ', ')]
        )
      end
    rescue StandardError => e
      Rails.logger.error "Failed to build dynamic definition load issues: #{e.message}"
      []
    end

    def self.describe(category, item)
      text = [helpers.link_to(item[:resource_name], item[:admin_path]), " (id #{item[:id]})"]
      text += [category == :unresolved_references ? ' -> ' : ' - ', item[:detail]] if item[:detail].present?
      helpers.safe_join(text)
    end

    def self.helpers
      ActionController::Base.helpers
    end

    # For example /admin/dynamic_models?filter%5Bid%5D=12&perform_action=edit
    def self.admin_edit_path(definition_class, id)
      Rails.application.routes.url_helpers.public_send("#{definition_class.base_route_name.pluralize}_path",
                                                       filter: { id: }, perform_action: 'edit')
    end

    def self.collect(issues, definition_class)
      definition_class.active_model_configurations.each do |definition|
        collect_not_generated(issues, definition_class, definition)
        cached = definition_class.definition_cache[definition.id]
        collect_option_issues(issues, definition_class, cached) if cached
      end
    end

    # A class is generated if the class registry has it. Definitions may share an implementation class.
    def self.collect_not_generated(issues, definition_class, definition)
      failure = definition_class.generation_failures[definition.id]
      generated = definition_class.models.key?(definition.implementation_model_name)
      return if generated && !failure

      if definition.table_or_view_ready?
        detail = failure || 'class not generated, no error recorded'
        add(issues, :failed_to_create, definition_class, definition, detail)
      else
        add(issues, :table_or_view_not_found, definition_class, definition)
      end
    end

    def self.collect_option_issues(issues, definition_class, cached)
      if cached.option_configs_parse_error
        add(issues, :options_parse_exception, definition_class, cached, cached.option_configs_parse_error)
      elsif cached.option_configs_have_unresolved_references?
        add(issues, :unresolved_references, definition_class, cached,
            cached.unresolved_model_reference_names.join(', '))
      end
    end

    def self.add(issues, category, definition_class, definition, detail = nil)
      issues[category] << {
        definition_class: definition_class,
        id: definition.id,
        resource_name: definition.resource_name,
        admin_path: admin_edit_path(definition_class, definition.id),
        detail: detail.to_s.lines.first.to_s.strip.truncate(MaxDetailLength)
      }
    end

    private_class_method :describe, :helpers, :admin_edit_path, :collect, :collect_not_generated,
                         :collect_option_issues, :add
  end
end
