module AdminHelper

  def edit_path id, opt={}
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

      these_filters[:disabled] = ['true', 'false']
      fo << :disabled

      fo.each do |filter_on|

        res << "<h4>Filter on: #{filter_on.to_s.humanize}</h4>"

        if filters_on_multiple
          filter = these_filters[filter_on]
        else
          filter = these_filters
        end


        if filter.first.last.is_a? String
          all_filters = {all: filter}
        else
          all_filters = filter
        end


        res << filter_btn('all', filter_on, nil) if all_filters.first.last.is_a?(Symbol)
        all_filters.each do |title, vals|

          if vals.is_a?( Symbol) || vals.is_a?( String)
            res << filter_btn(title, filter_on, vals)
          else

            res << "<div><p>#{title.to_s.humanize}</p>"
            res << filter_btn('all', filter_on, nil)
            if vals.is_a? Hash
              vals.each do |k,v|
                res << filter_btn(v, filter_on, k)
              end
            else
              vals.each do |v|
                res << filter_btn(v, filter_on, v)
              end
            end
            res << "</div>"
          end
        end
      end
    end

    res.html_safe
  end


end
