# frozen_string_literal: true

module AdminHelper
  def edit_path(id, opt = {})
    return unless id

    redir = { action: :edit, id: }
    redir.merge! opt
    url_for(redir)
  end

  def new_path(opt = {})
    redir = { action: :new }
    redir.merge! opt
    url_for(redir)
  end

  def admin_edit_cancel
    link_to 'cancel', '#', id: 'admin-edit-cancel', class: 'btn btn-danger'
  end

  def admin_edit_btn(id, options = {})
    return if no_edit

    if options[:copy]
      path = new_path(copy_with_id: options[:copy]&.id, filter: filter_params_permitted)
      link_to '', path, remote: true, class: 'edit-entity glyphicon glyphicon-copy copy-icon'
    else
      path = edit_path(id, filter: filter_params_permitted)
      link_to '', path, remote: true, class: 'edit-entity glyphicon glyphicon-pencil simple-admin-edit'
    end
  end

  # Use in forms where the object is not in the admin module (and so a specific path is needed)
  def admin_form_url
    ['', controller_path, object_instance.id].join('/')
  end

  #
  # Generate a select element for a single filter field, replacing the previous button-based filter UI.
  # The select uses the "chosen" plugin class for typed filtering of options.
  # @param [Symbol] filter_on - the filter parameter name
  # @param [Hash, Array] values - the available filter options
  #   Hash: { value => label } pairs
  #   Array: simple list of values (used as both value and label)
  # @param [Boolean] allow_not_set - whether to offer a "Not set" (IS NULL) option. Should be
  #   false for filters that aren't real nullable database columns (e.g. a computed/virtual
  #   filter like in_current_app_type), where "Not set" has no meaningful distinct value from "All".
  # @return [String] HTML safe string containing the select element
  def filter_select(filter_on, values, allow_not_set: true)
    current_filter = (filter_params || {}).dup
    key_present = current_filter.key?(filter_on)
    # A present key with a nil value means "Not set" (IS NULL) was selected and applied.
    # A missing key means "All" (no filter applied). Both stringify to '', so they must be
    # distinguished via key presence rather than comparing stringified values alone -
    # otherwise "Not set" and "All" are indistinguishable in the rendered dropdown.
    not_set_selected = key_present && current_filter[filter_on].nil?
    current_val = not_set_selected ? nil : current_filter[filter_on].to_s

    options = []
    options << content_tag(:option, 'All', value: '')
    if allow_not_set
      options << content_tag(:option, 'Not set', value: 'IS NULL', selected: not_set_selected ? 'selected' : nil)
    end

    if values.is_a?(Hash)
      values.each do |val, label|
        selected = !not_set_selected && val.to_s == current_val ? 'selected' : nil
        like_type = label.to_s.end_with?('__%')
        display_label = like_type ? label.to_s[0..-4] : label.to_s
        options << content_tag(:option, display_label, value: val, selected:)
      end
    elsif values.is_a?(Array)
      values.each do |val|
        selected = !not_set_selected && val.to_s == current_val ? 'selected' : nil
        options << content_tag(:option, val.to_s.humanize, value: val, selected:)
      end
    end

    content_tag(:select,
                safe_join(options),
                class: 'use-chosen filter-select',
                data: { filter_on: filter_on.to_s, nothing_selected_text: 'select filter' })
  end

  #
  # Returns filters merged with an auto-detected name filter when the context
  # provides a primary_model with a 'name' column and no explicit name filter
  # is defined. Falls back gracefully when helper-only context lacks filter_values_for.
  # @return [Hash]

  def show_filters
    return if view_embedded?
    return unless respond_to?(:filters) && filters

    show_disabled_filter = !respond_to?(:filters_prevent_disabled) || !filters_prevent_disabled

    these_filters = respond_to?(:effective_filters) ? effective_filters : filters.dup

    raw_filters_on = respond_to?(:effective_filters_on) ? effective_filters_on : filters_on

    fo = if raw_filters_on.is_a? Symbol
           [raw_filters_on]
         else
           raw_filters_on.dup
         end

    these_filters = { filters_on => these_filters } if these_filters.is_a? Array

    if current_admin && show_disabled_filter
      these_filters[:disabled] = %w[disabled enabled]
      fo << :disabled
    end

    res = ''
    res += render(partial: 'admin_handler/filters',
                  locals: { fo:, these_filters: })

    res.html_safe
  end

  def admin_app_type
    @app_type ||= current_user&.app_type || current_admin.matching_user&.app_type || Admin::AppType.active.first
  end

  def show_admin_heading(alt_title = nil, alt_sub_title = nil)
    alt_title ||= title
    alt_sub_title ||= sub_title
    res = <<~END_HTML
      <div class="panel panel-default admin-action-page">
        <div class="panel-heading">
          #{render partial: 'admin/common_templates/app_components_dropdown'}
          <h1 class="admin-title">#{alt_title} <small>#{alt_sub_title}</small>
            #{ link_to(
              '',
              help_page_path(
                library: :admin_reference,
                section: help_section,
                subsection: help_subsection,
                display_as: :embedded
              ),
              class: 'glyphicon glyphicon-question-sign small admin-help-icon',
              data: { remote: true,
                      toggle: 'collapse',
                      target: '#help-sidebar',
                      'working-target': '#help-sidebar-body' }
            ) }
            #{render partial: 'admin_handler/status_bar'}
            </h1>
        </div>
      </div>
    END_HTML

    res.html_safe
  end

  def hidden_filter_fields
    res = ''
    filter_params_permitted&.each do |filter|
      res += hidden_field_tag "filter[#{filter.first}]", filter.last
    end
    res.html_safe
  end

  def admin_last_updated_by_icon(list_item)
    return unless list_item.admin_id

    res = <<~END_HTML
      <span class="hidden">#{list_item.updated_at}</span>
      <span class="glyphicon glyphicon-info-sign" data-toggle="tooltip"  title="last updated by: #{list_item.admin_email} at #{list_item.updated_at}"></span>
    END_HTML

    res.html_safe
  end

  def admin_submit_and_cancel(form)
    res = <<~END_HTML
      #{hidden_field_tag :updated_at, object_instance.updated_at}
      #{form.submit class: 'btn btn-primary'}
      #{admin_edit_cancel}
    END_HTML

    res.html_safe
  end

  def index_list_item_boolean_field(list_val)
    if list_val
      '<span class="glyphicon glyphicon-check val-checked"><span class="hidden">1</span></span>'.html_safe
    else
      '<span class="val-unchecked"><span class="hidden">0</span></span>'.html_safe
    end
  end
end
