module AdminHelper

  def edit_path id
    redir = {action: :edit, id: id}
    
    url_for(redir)
  end 
  
  
  def admin_edit_cancel
     link_to 'cancel', "#", id: "admin-edit-cancel", class: "btn btn-danger" 
  end
  
  def admin_edit_btn id
     link_to '', edit_path(id), remote: true, class: 'edit-entity glyphicon glyphicon-pencil'
  end
end
