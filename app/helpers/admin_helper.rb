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
    
      res = "Filter: #{link_to("all", index_path, class: "btn btn-default btn-sm" )}"
      filters.each do |k,v|
        res << link_to(v, index_path(filter: {filters_on => k}), class: "btn btn-default btn-sm" )
      end 
    end
    
    res.html_safe
  end   
     
     
end
