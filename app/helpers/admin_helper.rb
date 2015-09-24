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
end
