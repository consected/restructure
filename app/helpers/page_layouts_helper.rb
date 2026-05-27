# frozen_string_literal: true

# Support the display of page layouts and panels
module PageLayoutsHelper
  #
  # Get an ordered list of page layout panels for the named layout
  # in the current user's app, or for any panels where the app type is NULL.
  # The definitions matching the current app always appear first, allowing them to override
  # app-types that are not set.
  # @param [String] layout_name - defaults to 'master' for master record related panels
  # @return [ActiveRecord::Relation]
  def page_layout_panels(layout_name: 'master')
    Admin::PageLayout
      .active
      .where(app_type_id: [nil, current_user.app_type_id], layout_name: layout_name)
      .order(Arel.sql('app_type_id ASC NULLS LAST, panel_position ASC'))
  end

  #
  # Get the first (or a set of) matching panel in the named layout, optionally with a specified
  # panel name and where the categories optionally includes the category.
  # If *set_of* is set (as an array of two symbols), a set of these entries from all the requested panels are compiled.
  # For example, this allows [:nav, :links] to get all the "links" definitions across all requested panels,
  # ordered by position within the app, then position across all apps (where app type is set to null in the record)
  # @param [String] panel_name - optional panel name to search for
  # @param [String] category - optional category included in :categories option
  # @param [String] layout_name - defaults to 'master' for master record related panels
  # @param [nil | Array{}] set_of - two method names to call to get the required values, such as [:nav, :links]
  # @return [Admin::PageLayout | Array | nil] single page layout definition or nil if not matched
  def page_layout_panel(panel_name: nil, category: nil, layout_name: 'master', set_of: nil)
    res = page_layout_panels(layout_name: layout_name)
    res = res.where(panel_name: panel_name) if panel_name
    res = res.select { |r| r.contains&.categories&.include?(category) } if category
    return res.first unless set_of

    res.map { |panel_def| panel_def.send(set_of.first)&.send(set_of.last) }
       .compact
       .reduce([], :concat)
       .uniq
       .compact
  end

  #
  # Resolve per-resource rendering metadata for a given resource name.
  # Returns a hash with resource_name, template_name, route_path, wrapper_class, and viewable_key,
  # or nil if the resource name cannot be resolved.
  # @param [String] resource_name - the resource name to resolve (e.g. 'activity_log__case_reviews')
  # @param [Symbol] context - :master_panel or :standalone_page
  # @param [String|nil] template_prefix - explicit template prefix override (e.g. 'page-'), or nil to use
  #   the resource-type default: activity log → '<suffix>-result-template', others → '-list-template'
  # @return [Hash, nil]
  def resource_render_info(resource_name, context:, template_prefix: nil)
    model = Resources::Models.find_by(resource_name: resource_name)
    model ||= Resources::Models.find_by(resource_item_name: resource_name.to_sym)

    unless model
      Rails.logger.warn "resource_render_info: could not resolve resource '#{resource_name}'"
      return nil
    end

    type = model[:type]

    # Handlebars templates are registered using the full, namespaced, pluralised
    # resource name with underscores replaced by hyphens (e.g.
    # `activity-log--case-reviews-main-result-template`, `dynamic-model--contact-infos-list-template`,
    # `scantron-ids-list-template`). Use the resource name itself (not the
    # stripped singular `hyphenated_name` from Resources::Models) to align with
    # the names produced by handlebars_template_tag in the search-results partials.
    resource_hyph = resource_name.to_s.hyphenate

    template_name = if !template_prefix.nil?
                      "#{resource_hyph}-#{template_prefix}result-template"
                    elsif %i[activity_log activity_log_type].include?(type)
                      # Activity logs use a context-dependent suffix:
                      # master panels → -main-result-template; standalone pages → -page-result-template
                      suffix = context == :master_panel ? 'main' : 'page'
                      "#{resource_hyph}-#{suffix}-result-template"
                    else
                      # Dynamic models and external identifiers use the plural list template
                      "#{resource_hyph}-list-template"
                    end

    wrapper_class = case type
                    when :dynamic_model then 'dynamic-model-generic-block'
                    when :external_identifier then 'external-id-generic-block'
                    else 'activity-logs-generic-block'
                    end

    {
      resource_name: resource_name,
      route_path: model[:base_route_segments],
      template_name: template_name,
      wrapper_class: wrapper_class,
      viewable_key: resource_name.to_sym
    }
  end

  #
  # Format active sublist values for Handlebars template rendering.
  # Converts arrays to comma-separated strings for use with the 'in' operator.
  # @param [Array|String|nil] values - array of values, 'all' string, or nil
  # @return [String] formatted value: 'all', 'none', comma-separated string, or empty string
  def format_active_values(values)
    return '' if values.nil?
    return 'all' if values == 'all'
    return 'none' if values.is_a?(Array) && values.empty?
    return values.join(',') if values.is_a?(Array)

    values.to_s
  end
end
