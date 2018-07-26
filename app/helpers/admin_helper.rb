module AdminHelper

  def edit_path id, opt={}
    return unless id
    redir = {action: :edit, id: id}
    redir.merge! opt
    url_for(redir)
  end


  def admin_edit_cancel
     link_to 'cancel', "#", id: "admin-edit-cancel", class: "btn btn-danger"
  end

  def admin_edit_btn id
    return if no_edit
    link_to '', edit_path(id, filter: params[:filter]), remote: true, class: 'edit-entity glyphicon glyphicon-pencil'
  end

  # Use in forms where the object is not in the admin module (and so a specific path is needed)
  def admin_form_url
    ['', controller_path, object_instance.id ].join('/')
  end

  def filter_btn title, filter_on, val

    filter = (params[:filter] || {}).dup

    prev_val = filter[filter_on].to_s
    filter[filter_on] = val.to_s

    if val.present? || title == 'all'
      link_to(title, index_path(filter: filter), class: "btn #{ val.blank? && prev_val.blank? || val.to_s == prev_val.to_s ? 'btn-primary' : 'btn-default'} btn-sm" )
    else
      ''
    end
  end

  def show_filters
    res = ""

    if respond_to?(:filters) && filters
      these_filters = filters.dup

      filters_on_multiple = false
      res = ''

      if filters_on.is_a? Symbol
        fo = [filters_on]
      else
        fo = filters_on
        filters_on_multiple = true
      end

      if these_filters.is_a? Array
        these_filters ={ filters_on => these_filters }
      end

      if current_admin
        these_filters[:disabled] = ['disabled', 'enabled']
        fo << :disabled
      end

      res << render( partial: 'admin_handler/filters', locals: {fo: fo, filters_on_multiple: filters_on_multiple, these_filters: these_filters})
    end

    res.html_safe
  end

  def hidden_filter_fields
    res = ""
    if params[:filter]
      params[:filter].each do |filter|
        res += hidden_field_tag "filter[#{filter.first}]", filter.last
      end
    end
    res.html_safe
  end

end
