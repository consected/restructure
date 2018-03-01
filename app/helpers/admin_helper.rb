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
     link_to '', edit_path(id, filter: params[:filter]), remote: true, class: 'edit-entity glyphicon glyphicon-pencil'
  end

  def show_filters
    res = ""

    if respond_to?(:filters) &&  filters

      filters_on_multiple = false
      res = ''

      if filters_on.is_a? Symbol
        fo = [filters_on]
      else
        fo = filters_on
        filters_on_multiple = true
      end

      fo.each do |filter_on|

        res << "<h4>Filter on: #{filter_on.to_s.humanize}</h4>"

        if filters_on_multiple
          filter = filters[filter_on]
        else
          filter = filters
        end


        if filter.first.last.is_a? String
          all_filters = {all: filter}
        else
          all_filters = filter
        end


        res << "#{link_to("all", index_path(filter: ""), class: "btn btn-default btn-sm" )}" if all_filters.first.last.is_a?(Symbol)
        all_filters.each do |title, vals|

          if vals.is_a?( Symbol) || vals.is_a?( String)
            res << link_to(title, index_path(filter: {filter_on => vals}), class: "btn btn-default btn-sm" )
          else

            res << "<div><p>#{title.to_s.humanize}</p>"
            res << "#{link_to("all", index_path(filter: ""), class: "btn btn-default btn-sm" )}"
            if vals.is_a? Hash
              vals.each do |k,v|
                res << link_to(v, index_path(filter: {filter_on => k}), class: "btn btn-default btn-sm" )
              end
            else
              vals.each do |v|
                res << link_to(v, index_path(filter: {filter_on => v}), class: "btn btn-default btn-sm" )
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
