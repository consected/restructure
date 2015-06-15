module ApplicationHelper
  
  def current_email
    return nil unless current_user || current_admin
    (current_user || current_admin).email
  end
end
