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

      if filters.first.last.is_a? String
        all_filters = {all: filters}
      else
        all_filters = filters
      end
      res = ''

      all_filters.each do |title, vals|
        
        res << "<div><p>#{title.to_s.humanize}</p>"
        res << "#{link_to("all", index_path(filter: ""), class: "btn btn-default btn-sm" )}"
        if vals.is_a? Hash
          vals.each do |k,v|
            res << link_to(v, index_path(filter: {filters_on => k}), class: "btn btn-default btn-sm" )
          end
        else
          vals.each do |v|
            res << link_to(v, index_path(filter: {filters_on => v}), class: "btn btn-default btn-sm" )
          end
        end
        res << "</div>"
      end
    end

    res.html_safe
  end


end
