# frozen_string_literal: true

module AdminHelper
  def edit_path(id, opt = {})
    return unless id

    redir = { action: :edit, id: id }
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
      path = new_path(copy_with_id: options[:copy]&.id)
      link_to '', path, remote: true, class: 'edit-entity glyphicon glyphicon-copy copy-icon'
    else
      path = edit_path(id, filter: filter_params_permitted)
      link_to '', path, remote: true, class: 'edit-entity glyphicon glyphicon-pencil'
    end
  end

  # Use in forms where the object is not in the admin module (and so a specific path is needed)
  def admin_form_url
    ['', controller_path, object_instance.id].join('/')
  end

  def filter_btn(title, filter_on, val)
    res = ''

    filter = (filter_params || {}).dup
    prev_val = filter[filter_on].to_s
    filter[filter_on] = val.to_s

    unless title == 'all' || title.to_s.include?('__') || @shown_filter_break
      @shown_filter_break = true
      res = '<p class="filter-small-gap">&nbsp;</p>'.html_safe
    end

    if val.present? || title == 'all'
      like_type = title.to_s.end_with?('__%')
      title = title[0..-4] if like_type
      linkres = link_to(title, index_path(filter: filter),
                        class: "btn #{val.blank? && prev_val.blank? || val.to_s == prev_val.to_s ? 'btn-primary' : 'btn-default'} btn-sm #{like_type ? 'like-type' : ''}")
      if like_type
        @shown_filter_break = false
        res += "<p class=\"like-type\">#{linkres}</p>".html_safe
      else
        res += linkres.html_safe
      end
      res.html_safe
    else
      ''
    end
  end

  def show_filters
    return if view_embedded?
    return unless respond_to?(:filters) && filters

    these_filters = filters.dup

    filters_on_multiple = false
    res = ''

    if filters_on.is_a? Symbol
      fo = [filters_on]
    else
      fo = filters_on
      filters_on_multiple = true
    end

    these_filters = { filters_on => these_filters } if these_filters.is_a? Array

    if current_admin
      these_filters[:disabled] = %w[disabled enabled]
      fo << :disabled
    end

    res += render(partial: 'admin_handler/filters',
                  locals: { fo: fo, filters_on_multiple: filters_on_multiple, these_filters: these_filters })

    res.html_safe
  end

  def show_admin_heading(alt_title = nil)
    alt_title ||= title
    res = <<~END_HTML
      <div class="panel panel-default admin-action-page">
        <div class="panel-heading">#{' '}
          <h1 class="admin-title">#{alt_title}
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
end
